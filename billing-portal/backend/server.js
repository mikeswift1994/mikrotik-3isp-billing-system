# Billing Portal Backend - Node.js + Express
# Database: SQLite for user profiles and expiration dates
# Features: User authentication, profile management, expiration checks, API endpoints

const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const cron = require('node-cron');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-this';

// Middleware
app.use(express.json());
app.use(cors());
app.use(express.static(path.join(__dirname, 'public')));

// Initialize SQLite Database
const db = new sqlite3.Database('./billing.db', (err) => {
    if (err) console.error('Database error:', err);
    else console.log('Connected to SQLite database');
});

// Create tables if they don't exist
db.serialize(() => {
    // Users table
    db.run(`CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        email TEXT NOT NULL,
        pppoe_user TEXT UNIQUE NOT NULL,
        pppoe_password TEXT NOT NULL,
        package_id INTEGER NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        expiry_date DATETIME NOT NULL,
        is_active BOOLEAN DEFAULT 1,
        status TEXT DEFAULT 'active'
    )`);

    // Packages table
    db.run(`CREATE TABLE IF NOT EXISTS packages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        speed_mbps INTEGER NOT NULL,
        price DECIMAL(10,2) NOT NULL,
        duration_days INTEGER NOT NULL,
        description TEXT
    )`);

    // Billing records
    db.run(`CREATE TABLE IF NOT EXISTS billing_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
        expiry_date DATETIME NOT NULL,
        status TEXT DEFAULT 'pending',
        FOREIGN KEY(user_id) REFERENCES users(id)
    )`);

    // Queue configuration (for speed limits)
    db.run(`CREATE TABLE IF NOT EXISTS queue_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        pppoe_ip TEXT NOT NULL,
        speed_limit INTEGER NOT NULL,
        packet_mark TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(user_id) REFERENCES users(id)
    )`);
});

// ============================================================
// SEED DEFAULT PACKAGES
// ============================================================

const seedPackages = () => {
    const packages = [
        { name: '20 Mbps Plan', speed_mbps: 20, price: 10.00, duration_days: 30 },
        { name: '30 Mbps Plan', speed_mbps: 30, price: 15.00, duration_days: 30 },
        { name: '50 Mbps Plan', speed_mbps: 50, price: 25.00, duration_days: 30 },
        { name: '100 Mbps Plan', speed_mbps: 100, price: 40.00, duration_days: 30 },
        { name: '200 Mbps Plan', speed_mbps: 200, price: 70.00, duration_days: 30 },
        { name: '500 Mbps Plan', speed_mbps: 500, price: 150.00, duration_days: 30 }
    ];

    packages.forEach(pkg => {
        db.run(
            `INSERT OR IGNORE INTO packages (name, speed_mbps, price, duration_days) 
             VALUES (?, ?, ?, ?)`,
            [pkg.name, pkg.speed_mbps, pkg.price, pkg.duration_days]
        );
    });
};

seedPackages();

// ============================================================
// AUTHENTICATION ENDPOINTS
// ============================================================

// Register User
app.post('/api/auth/register', async (req, res) => {
    const { username, password, email, package_id } = req.body;

    if (!username || !password || !email || !package_id) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const pppoe_user = `user_${username}`;
    const pppoe_password = Math.random().toString(36).substring(2, 15);
    
    // Calculate expiry date (30 days from now)
    const expiry_date = new Date();
    expiry_date.setDate(expiry_date.getDate() + 30);

    db.run(
        `INSERT INTO users (username, password, email, pppoe_user, pppoe_password, package_id, expiry_date) 
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [username, hashedPassword, email, pppoe_user, pppoe_password, package_id, expiry_date],
        function(err) {
            if (err) {
                return res.status(400).json({ error: 'User already exists or invalid package' });
            }
            res.status(201).json({
                message: 'User registered successfully',
                user_id: this.lastID,
                pppoe_user,
                pppoe_password,
                expiry_date
            });
        }
    );
});

// Login User
app.post('/api/auth/login', (req, res) => {
    const { username, password } = req.body;

    db.get(`SELECT * FROM users WHERE username = ?`, [username], async (err, user) => {
        if (err || !user) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const token = jwt.sign(
            { user_id: user.id, username: user.username },
            JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.json({
            token,
            user: {
                id: user.id,
                username: user.username,
                email: user.email,
                pppoe_user: user.pppoe_user,
                expiry_date: user.expiry_date,
                status: user.status
            }
        });
    });
});

// ============================================================
// PROTECTED ROUTES MIDDLEWARE
// ============================================================

const verifyToken = (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'No token provided' });
    }

    jwt.verify(token, JWT_SECRET, (err, decoded) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid token' });
        }
        req.user_id = decoded.user_id;
        next();
    });
};

// ============================================================
// USER ENDPOINTS
// ============================================================

// Get User Profile
app.get('/api/user/profile', verifyToken, (req, res) => {
    db.get(`SELECT id, username, email, pppoe_user, package_id, expiry_date, status 
            FROM users WHERE id = ?`, [req.user_id], (err, user) => {
        if (err || !user) {
            return res.status(404).json({ error: 'User not found' });
        }

        db.get(`SELECT * FROM packages WHERE id = ?`, [user.package_id], (err, pkg) => {
            res.json({
                ...user,
                package: pkg,
                days_remaining: Math.ceil((new Date(user.expiry_date) - new Date()) / (1000 * 60 * 60 * 24))
            });
        });
    });
});

// ============================================================
// BILLING ENDPOINTS
// ============================================================

// Check Expiration Status (for portal pop-up)
app.get('/api/billing/status', verifyToken, (req, res) => {
    db.get(`SELECT expiry_date, status FROM users WHERE id = ?`, [req.user_id], (err, user) => {
        if (err || !user) {
            return res.status(404).json({ error: 'User not found' });
        }

        const now = new Date();
        const expiry = new Date(user.expiry_date);
        const daysRemaining = Math.ceil((expiry - now) / (1000 * 60 * 60 * 24));
        const isExpired = now > expiry;
        const expiringsoon = daysRemaining <= 3 && daysRemaining > 0;

        res.json({
            status: user.status,
            expiry_date: user.expiry_date,
            days_remaining: daysRemaining,
            is_expired: isExpired,
            expiring_soon: expiringoon,
            show_popup: isExpired || expiringoon
        });
    });
});

// Renew Subscription
app.post('/api/billing/renew', verifyToken, (req, res) => {
    const { package_id } = req.body;

    db.get(`SELECT expiry_date FROM users WHERE id = ?`, [req.user_id], (err, user) => {
        if (err || !user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Calculate new expiry date
        const newExpiry = new Date(user.expiry_date);
        newExpiry.setDate(newExpiry.getDate() + 30);

        db.run(`UPDATE users SET expiry_date = ?, status = 'active' WHERE id = ?`,
            [newExpiry, req.user_id],
            function(err) {
                if (err) {
                    return res.status(500).json({ error: 'Failed to renew subscription' });
                }

                db.run(`INSERT INTO billing_records (user_id, amount, expiry_date, status)
                        VALUES (?, ?, ?, 'completed')`,
                    [req.user_id, 25.00, newExpiry]
                );

                res.json({
                    message: 'Subscription renewed successfully',
                    new_expiry_date: newExpiry
                });
            }
        );
    });
});

// Get Billing History
app.get('/api/billing/history', verifyToken, (req, res) => {
    db.all(`SELECT * FROM billing_records WHERE user_id = ? ORDER BY payment_date DESC`,
        [req.user_id],
        (err, records) => {
            if (err) {
                return res.status(500).json({ error: 'Failed to fetch billing history' });
            }
            res.json(records);
        }
    );
});

// ============================================================
// ADMIN ENDPOINTS
// ============================================================

// Get All Users (Admin only)
app.get('/api/admin/users', (req, res) => {
    const adminToken = req.headers.authorization?.split(' ')[1];
    
    if (adminToken !== process.env.ADMIN_TOKEN) {
        return res.status(403).json({ error: 'Unauthorized' });
    }

    db.all(`SELECT id, username, email, pppoe_user, package_id, expiry_date, status FROM users`,
        (err, users) => {
            if (err) {
                return res.status(500).json({ error: 'Failed to fetch users' });
            }
            res.json(users);
        }
    );
});

// ============================================================
// SCHEDULED TASKS
// ============================================================

// Check expired users every hour
cron.schedule('0 * * * *', () => {
    db.run(`UPDATE users SET status = 'expired' WHERE expiry_date < datetime('now')`, (err) => {
        if (err) console.error('Error updating expired users:', err);
        else console.log('Expired users updated at', new Date());
    });
});

// ============================================================
// ERROR HANDLING
// ============================================================

app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
    console.log(`Billing Portal Backend running on http://localhost:${PORT}`);
});

module.exports = app;
