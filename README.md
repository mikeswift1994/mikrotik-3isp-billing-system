# Mikrotik 3-ISP Load Balancing & Billing System

Complete Mikrotik RouterOS configuration for 3 ISP failover/load balancing with PPPoE server, firewall security, and web-based billing portal with expiration notifications.

## 📋 Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [System Requirements](#system-requirements)
- [Installation Guide](#installation-guide)
- [Configuration](#configuration)
- [Billing Portal](#billing-portal)
- [Speed Limiting & Speedtest](#speed-limiting--speedtest)
- [Troubleshooting](#troubleshooting)

---

## ✨ Features

### RouterOS Configuration
✅ **3 ISP Load Balancing** - Distribute traffic across 3 ISP connections (ether1, ether2, ether3)
✅ **Automatic Failover** - Health checks every 30 seconds with automatic failover
✅ **PPPoE Server** - Built-in PPPoE server on ether4 (172.22.162.1/24)
✅ **6 Speed Profiles** - 20Mbps, 30Mbps, 50Mbps, 100Mbps, 200Mbps, 500Mbps
✅ **Firewall Security** - Complete NAT/masquerade to hide internal setup from ISPs
✅ **LAN Network** - Ether5 configured as LAN (10.10.10.1/24) with DHCP

### Billing Portal
✅ **User Authentication** - Secure login/registration system
✅ **Expiration Notifications** - Automatic pop-ups when account expires or expiring soon
✅ **Subscription Management** - Easy renewal and plan upgrades
✅ **Speed Profile Management** - Assign different speeds to users
✅ **Billing History** - Track all transactions
✅ **Admin Dashboard** - Manage all users and subscriptions

### Speed Control
✅ **Real Speed Limiting** - Backend enforces actual speeds via queue rules
✅ **Speedtest Compatible** - Users get exact speeds on speedtest.net
✅ **Per-User Queuing** - Each user limited independently
✅ **Burst Support** - Configurable burst speeds

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    INTERNET (3 ISPs)                        │
│         ether1 (ISP1) | ether2 (ISP2) | ether3 (ISP3)       │
└──────────────┬────────────────┬────────────────┬────────────┘
               │                │                │
        ┌──────▼────────────────▼────────────────▼──────┐
        │                                                │
        │        MIKROTIK RouterOS                       │
        │   ┌──────────────────────────────────┐        │
        │   │  Load Balancing & Failover       │        │
        │   │  - Per-connection distribution   │        │
        │   │  - Health monitoring (30s)       │        │
        │   │  - Automatic ISP switching       │        │
        │   └──────────────────────────────────┘        │
        │                                                │
        │   ┌──────────────────────────────────┐        │
        │   │  Firewall & Security             │        │
        │   │  - Source NAT (masquerade)       │        │
        │   │  - Anti-DDoS rules               │        │
        │   │  - Port scan protection          │        │
        │   └──────────────────────────────────┘        │
        │                                                │
        │   ┌──────────────────────────────────┐        │
        │   │  PPPoE Server (ether4)           │        │
        │   │  - 6 Speed Profiles              │        │
        │   │  - Queue-based limiting          │        │
        │   │  - Per-user packet marking       │        │
        │   └──────────────────────────────────┘        │
        │                                                │
        └──────────────┬──────────────┬──────────────────┘
                       │              │
            ┌──────────▼──┐  ┌───────▼──────────┐
            │  PPPoE Clients   │  LAN (ether5)     │
            │  (Customers)     │  10.10.10.1/24    │
            └─────────────┘  └───────────────┘
                  │
         ┌────────▼────────────┐
         │                     │
    ┌────▼──────┐      ┌──────▼───┐
    │ Web Browser│      │Speedtest │
    │(Billing    │      │(Actual   │
    │Portal)     │      │Speed)    │
    └────────────┘      └──────────┘
         │
    ┌────▼─────────────────────────┐
    │ Billing Portal Backend        │
    │ (Node.js + SQLite)            │
    │                               │
    │ - User Management             │
    │ - Expiration Checks           │
    │ - Speed Profile Assignment    │
    │ - Billing History             │
    └───────────────────────────────┘
```

---

## 🛠️ System Requirements

### Hardware
- **Mikrotik RouterOS** (Tested on: RouterOS v7.x+)
- **Minimum 256MB RAM** (recommended 512MB+)
- **5 Ethernet Ports** minimum (3 ISP + PPPoE + LAN)
- **Storage**: 50MB free for configuration and logs

### Software
- **RouterOS v6.48+** or **v7.x+**
- **Node.js v14+** (for billing portal backend)
- **SQLite3** (included with Node.js)
- **Modern Web Browser** (Chrome, Firefox, Safari, Edge)

### Network
- 3 ISP connections with DHCP or static IPs
- Minimum 2 Mbps recommended per ISP (for load balancing to work effectively)

---

## 📥 Installation Guide

### Step 1: Prepare Mikrotik Router

1. **Access Mikrotik Router**
   ```bash
   # Via SSH
   ssh admin@192.168.88.1
   
   # Or via WinBox GUI
   # Open WinBox.exe and connect to your router
   ```

2. **Reset to Factory Defaults (Optional)**
   ```
   /system reset-configuration
   ```

3. **Backup Current Configuration**
   ```
   /system backup make name=backup-pre-isp
   ```

### Step 2: Configure Interfaces & DHCP

Execute the first script to configure all interfaces:

```
# In Mikrotik Terminal/WinBox
/system script run file=01-interfaces-setup.rsc
```

Or manually paste the contents of `routeros-scripts/01-interfaces-setup.rsc`

### Step 3: Configure Load Balancing & Failover

```
/system script run file=02-load-balancing-failover.rsc
```

### Step 4: Configure Firewall & Security

```
/system script run file=03-firewall-security.rsc
```

### Step 5: Configure PPPoE Server

```
/system script run file=04-pppoe-server-setup.rsc
```

### Step 6: Verify Configuration

```bash
# Check interfaces
/interface print

# Check IP addresses
/ip address print

# Check routes
/ip route print

# Check PPPoE Server status
/interface pppoe-server server print

# Check queues
/queue tree print

# Check firewall rules
/ip firewall filter print
/ip firewall mangle print
/ip firewall nat print
```

---

## ⚙️ Configuration Details

### Interface Configuration

| Interface | Purpose | IP Address | DHCP |
|-----------|---------|-----------|------|
| ether1 | ISP 1 (Primary) | DHCP | Yes |
| ether2 | ISP 2 (Secondary) | DHCP | Yes |
| ether3 | ISP 3 (Tertiary) | DHCP | Yes |
| ether4 | PPPoE Server | 172.22.162.1/24 | No |
| ether5 | LAN Network | 10.10.10.1/24 | Yes |

### PPPoE Users Setup

Add users via Winbox or CLI:

```
/ppp secret
add name="customer1" password="password123" service=pppoe profile=ppp-20mbps disabled=no
add name="customer2" password="password456" service=pppoe profile=ppp-50mbps disabled=no
```

Or use the Billing Portal to auto-create users.

### Load Balancing Method

The system uses **per-connection load balancing** with 3:1 distribution:

- **33% of new connections** → ISP1
- **33% of new connections** → ISP2
- **33% of new connections** → ISP3

Each connection stays on the same ISP for its duration.

### Failover Mechanism

- **Health Check Interval**: 30 seconds
- **Test Target**: 8.8.8.8 (Google DNS)
- **Ping Count**: 2 packets
- **Action**: Automatically disables failing ISP route

When ISP1 fails:
1. Health check detects no response
2. ISP1 route is disabled
3. New connections route through ISP2 or ISP3
4. When ISP1 comes back online, it's automatically re-enabled

---

## 💳 Billing Portal

### Backend Setup

1. **Install Node.js Dependencies**
   ```bash
   cd billing-portal/backend
   npm install
   ```

2. **Start Backend Server**
   ```bash
   npm start
   # Server runs on http://localhost:3000
   ```

3. **Set Environment Variables** (optional)
   ```bash
   # Create .env file
   PORT=3000
   JWT_SECRET=your-very-secret-key-change-this
   ADMIN_TOKEN=your-admin-token
   ```

### Frontend Setup

1. **Serve Frontend Files**
   ```bash
   # Using Python
   cd billing-portal/frontend
   python -m http.server 8000
   
   # Or using Node.js http-server
   npm install -g http-server
   http-server
   ```

2. **Access Portal**
   - Login: `http://localhost:8000/login.html`
   - Dashboard: `http://localhost:8000/index.html`

### API Endpoints

#### Authentication
```
POST   /api/auth/login          - Login user
POST   /api/auth/register       - Register new user
```

#### User Profile
```
GET    /api/user/profile        - Get user info
```

#### Billing
```
GET    /api/billing/status      - Check expiration status
POST   /api/billing/renew       - Renew subscription
GET    /api/billing/history     - Get billing records
```

#### Admin
```
GET    /api/admin/users         - List all users (admin only)
```

### Creating Users via Portal

1. **Register**
   - Click "Register here"
   - Fill in username, email, password
   - Select internet plan (20-500 Mbps)
   - Submit

2. **Auto-Generated Credentials**
   - PPPoE Username: `user_<username>`
   - PPPoE Password: Auto-generated random string
   - Expiry Date: 30 days from registration

3. **PPPoE Connection**
   - Customer configures PPPoE client with:
     - Server: Router's PPPoE-Server interface (172.22.162.x)
     - Username: From portal
     - Password: From portal

---

## 📊 Speed Limiting & Speedtest

### How Speed Limiting Works

The system uses **hierarchical queuing** to enforce speeds:

1. **Profile Assignment**
   - User registers with 50 Mbps plan
   - PPP profile `ppp-50mbps` assigned
   - IP range: `172.22.162.201-172.22.162.225`

2. **Packet Marking**
   - PPPoE session connects
   - Client IP matches range
   - Firewall rule marks packets as `pkt-50mbps`

3. **Queue Enforcement**
   - Marked packets go to queue tree
   - Queue rule limits to **exactly 50 Mbps**
   - Burst: 50 Mbps for 5 seconds

4. **Speedtest Result**
   - Client runs speedtest.net
   - Tests actual bandwidth
   - Shows **real 50 Mbps** (not fake)

### Queue Configuration

Each speed tier has identical configuration:

```
/queue tree
add name="queue-50mbps" 
    parent=global-out 
    packet-mark="pkt-50mbps"
    limit-at=50M          # Guaranteed 50 Mbps
    max-limit=50M         # Never exceed 50 Mbps
    burst-limit=50M       # Burst same as max
    burst-time=5s         # Burst for 5 seconds
    priority=8            # Lower priority
```

### Modifying Speed Limits

To change a user's speed:

**Via CLI:**
```
# Update PPP profile
/ppp profile set ppp-50mbps rate-limit=75M/75M

# Or update queue
/queue tree set [find name="queue-50mbps"] max-limit=75M
```

**Via Portal:**
- Admin panel → Users → Edit Speed
- System updates both profile and queue automatically

---

## 🔒 Security Features

### Firewall Rules

1. **Source NAT (Masquerade)**
   - All outgoing traffic masked with router's IP
   - ISPs cannot see internal network structure
   - Prevents provider detection of load balancing

2. **Connection Tracking**
   - TCP: 1 hour timeout
   - UDP: 10 minutes timeout
   - ICMP: 10 seconds timeout

3. **Anti-DDoS Protection**
   - SYN flood protection (rate limiting)
   - Port scan detection
   - Invalid packet dropping

4. **Traceroute Blocking**
   - ICMP type 11 (Time Exceeded) blocked
   - Prevents external traceroute discovery

5. **Management Access**
   - SSH (port 22) only from LAN
   - WinBox (port 8291) only from LAN
   - Prevents remote management

### Hiding Setup from ISPs

✅ All traffic masqueraded (source NAT)
✅ No DNS leaks (internal DNS hidden)
✅ No ICMP responses to external pings
✅ No time-exceeded messages (traceroute blocked)
✅ No UPnP exposure
✅ No management ports exposed

---

## 🐛 Troubleshooting

### Issue: ISP Routes Constantly Failing

**Symptoms:**
- Health check shows all ISPs down
- No internet connectivity

**Solution:**
```bash
# Check if DHCP clients are running
/ip dhcp-client print

# If disabled, enable them
/ip dhcp-client enable [find interface=ISP1]
/ip dhcp-client enable [find interface=ISP2]
/ip dhcp-client enable [find interface=ISP3]

# Check if ISPs have IP addresses
/ip address print

# Manually ping each ISP's gateway
/ping 8.8.8.8 interface=ISP1
```

### Issue: PPPoE Clients Can't Connect

**Symptoms:**
- PPPoE authentication fails
- Connection timeout

**Solution:**
```bash
# Verify PPPoE server is enabled
/interface pppoe-server server print

# Check if server is enabled
# (should show enabled=yes)

# Verify PPPoE secrets exist
/ppp secret print

# Check firewall rules aren't blocking PPPoE
/ip firewall filter print
# Look for rules blocking dst-port=1194
```

### Issue: Users Not Getting Correct Speed

**Symptoms:**
- User speed doesn't match profile
- Speedtest shows different speed

**Solution:**
```bash
# Check queue assignment
/queue tree print

# Verify packet marking rules
/ip firewall mangle print chain=postrouting

# Check if user's IP is in correct range
# Example for 50 Mbps: should be 172.22.162.201-172.22.162.225

# Monitor real-time traffic
/tool traffic-monitor print

# Check queue stats
/queue tree print stats
```

### Issue: Load Balancing Not Working

**Symptoms:**
- All traffic using one ISP
- Load distribution uneven

**Solution:**
```bash
# Check connection marks
/ip firewall mangle print chain=prerouting

# Verify routing marks are applied
/ip route print

# Monitor connections
/ip firewall connection tracking print

# Reset mangle rules and reapply
/ip firewall mangle reset
# Then re-run: /system script run file=02-load-balancing-failover.rsc
```

### Issue: Billing Portal Not Accessible

**Symptoms:**
- Cannot reach login page
- Connection refused

**Solution:**
```bash
# Verify backend is running
ps aux | grep node

# Check if port 3000 is listening
netstat -tuln | grep 3000

# Restart backend
cd billing-portal/backend
npm restart

# Check database
ls -la billing.db

# Verify CORS is enabled in server.js
# Should have: app.use(cors());
```

### Issue: Expiration Popup Not Showing

**Symptoms:**
- Portal doesn't show expiration warnings
- Expired users still have access

**Solution:**
```bash
# Check billing status endpoint
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/api/billing/status

# Verify user's expiry date
sqlite3 billing.db \
  "SELECT username, expiry_date, status FROM users;"

# Manually update expired users (if needed)
sqlite3 billing.db \
  "UPDATE users SET status='expired' WHERE expiry_date < datetime('now');"

# Restart backend
npm restart
```

---

## 📱 Daily Operations

### Adding New Customer

1. Customer registers on billing portal
2. System auto-creates PPPoE account
3. Customer receives PPPoE credentials
4. Customer configures PPPoE client
5. Internet access enabled immediately

### Monitoring System

```bash
# Check all ISP links
/interface print
/ip address print

# Monitor load balancing
/ip firewall mangle print
/ip route print

# Check queue status
/queue tree print stats

# View PPPoE active sessions
/interface pppoe-server print
/ppp active print

# Check billing portal
curl http://localhost:3000/api/admin/users \
  -H "Authorization: YOUR_ADMIN_TOKEN"
```

### Regular Maintenance

- **Weekly**: Review billing reports
- **Monthly**: Check for expired accounts
- **Quarterly**: Update firewall rules
- **Bi-annually**: Upgrade RouterOS (backup first!)

---

## 📞 Support & Updates

For issues, questions, or improvements:

1. Check logs: `/log print`
2. Review this documentation
3. Test individual components
4. Restore from backup if needed: `/system backup restore name=backup-pre-isp`

---

## 📄 License

This configuration is provided as-is for ISP operations and billing management.

---

**Last Updated:** August 2026
**Version:** 1.0.0
**Compatible RouterOS:** v6.48+ to v7.x+
