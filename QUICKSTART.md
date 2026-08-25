# Quick Start Guide - Mikrotik 3-ISP Billing System

## ⚡ 5-Minute Setup

This guide gets your system running in minutes.

---

## Prerequisites

✅ Mikrotik RouterOS v6.48+ or v7.x+
✅ 5 Ethernet ports (3 ISP + PPPoE + LAN)
✅ Node.js v14+ installed on Linux/Windows server
✅ Access to router via SSH or WinBox

---

## Phase 1: Router Configuration (10 minutes)

### Step 1: Connect to Router

**Via SSH:**
```bash
ssh admin@192.168.88.1
```

**Via WinBox:**
- Download from mikrotik.com
- Click "Connect" and enter 192.168.88.1

### Step 2: Load Configuration Scripts

Copy each script content to your router terminal:

1. **Setup Interfaces & DHCP**
   ```
   /system script add name="setup-interfaces" source={PASTE_CONTENT_OF_01-interfaces-setup.rsc}
   /system script run setup-interfaces
   ```

2. **Setup Load Balancing**
   ```
   /system script add name="setup-lb" source={PASTE_CONTENT_OF_02-load-balancing-failover.rsc}
   /system script run setup-lb
   ```

3. **Setup Firewall**
   ```
   /system script add name="setup-firewall" source={PASTE_CONTENT_OF_03-firewall-security.rsc}
   /system script run setup-firewall
   ```

4. **Setup PPPoE Server**
   ```
   /system script add name="setup-pppoe" source={PASTE_CONTENT_OF_04-pppoe-server-setup.rsc}
   /system script run setup-pppoe
   ```

### Step 3: Verify Configuration

```
# Check interfaces are configured
/interface print

# Check IP addresses assigned
/ip address print

# Check PPPoE server is running
/interface pppoe-server print

# Check routes created
/ip route print

# Check firewall rules
/ip firewall nat print
```

**Expected Output:**
- ether1, ether2, ether3 with DHCP IPs
- ether4 as PPPoE-Server interface
- ether5 as LAN bridge (10.10.10.1/24)
- 3 routes with load balancing marks
- NAT masquerade rule for security

---

## Phase 2: Billing Portal Setup (5 minutes)

### Step 1: Install Backend Dependencies

```bash
cd billing-portal/backend
npm install
```

### Step 2: Create Environment File

```bash
cp .env.example .env
```

Edit `.env` and change:
```
JWT_SECRET=change-this-to-something-random
ADMIN_TOKEN=your-admin-token-here
```

### Step 3: Start Backend Server

```bash
npm start
# Server runs on http://localhost:3000
```

### Step 4: Serve Frontend

In a new terminal:

```bash
cd billing-portal/frontend
python -m http.server 8000
# Or: npx http-server
```

### Step 5: Access Portal

Open browser and go to:
```
http://localhost:8000/login.html
```

---

## Phase 3: First Customer Setup (2 minutes)

### Option A: Register via Portal

1. Click **"Register here"**
2. Fill in:
   - Username: `john_doe`
   - Email: `john@example.com`
   - Password: `securepass123`
   - Plan: `50 Mbps`
3. Click **Create Account**
4. You'll receive:
   - PPPoE Username: `user_john_doe`
   - PPPoE Password: `[auto-generated]`

### Option B: Add User via Router

```
/ppp secret
add name="customer1" password="mypassword" service=pppoe profile=ppp-50mbps disabled=no
```

### Customer PPPoE Configuration

Customer connects with:
- **Server**: Your router's PPPoE interface IP (172.22.162.1)
- **Username**: From portal or router
- **Password**: From portal or router
- **Expected Speed**: 50 Mbps (after connecting)

**Test Speed:**
```bash
# From customer's device
speedtest-cli
# Should show ~50 Mbps
```

---

## Common Commands Quick Reference

### Monitor Active Users
```
/ppp active print
```

### Check Queue Status
```
/queue tree print stats
```

### View Load Distribution
```
/ip firewall mangle print
/ip route print
```

### Check ISP Health
```
/ping 8.8.8.8 interface=ether1
/ping 8.8.8.8 interface=ether2
/ping 8.8.8.8 interface=ether3
```

### View System Logs
```
/log print
```

### Renew User (Portal)
- Login to http://localhost:8000/login.html
- Click **"Renew Subscription"**
- Choose plan and duration
- Click **"Pay"** (demo doesn't charge)

---

## Testing Checklist

- [ ] Can connect to PPPoE from customer device
- [ ] Customer gets IP from PPPoE pool (172.22.162.x)
- [ ] Customer can ping router (172.22.162.1)
- [ ] Customer has internet access through ISP
- [ ] Speedtest shows correct speed tier
- [ ] Can log into billing portal with customer account
- [ ] Can see "Days Remaining" in portal dashboard
- [ ] Expiration warning appears 3 days before expiry

---

## Troubleshooting Quick Fixes

### "Can't connect to PPPoE"
```
# Enable PPPoE server
/interface pppoe-server server set enabled=yes

# Verify interface exists
/interface pppoe-server print
```

### "No internet speed"
```
# Check if queues are configured
/queue tree print

# Verify packet marking
/ip firewall mangle print chain=postrouting
```

### "Portal shows error"
```bash
# Check backend is running
ps aux | grep node

# Restart backend
cd billing-portal/backend
npm restart
```

### "All ISPs show no connection"
```
# Check DHCP clients
/ip dhcp-client print

# Enable if disabled
/ip dhcp-client enable [find]
```

---

## Next Steps

1. **Add Multiple ISPs**: Edit scripts to configure WAN interfaces with static IPs
2. **Enable HTTPS**: Use Let's Encrypt for portal security
3. **Setup Backups**: Configure automatic router/database backups
4. **Add Email Notifications**: Configure SMTP for expiration alerts
5. **Monitor Traffic**: Set up Grafana/Prometheus for analytics

---

## File Structure Reference

```
mikrotik-3isp-billing-system/
├── README.md                          # Full documentation
├── QUICKSTART.md                      # This file
├── routeros-scripts/
│   ├── 01-interfaces-setup.rsc       # Interface & DHCP config
│   ├── 02-load-balancing-failover.rsc # Load balancing setup
│   ├── 03-firewall-security.rsc      # Firewall & NAT rules
│   └── 04-pppoe-server-setup.rsc     # PPPoE server config
├── billing-portal/
│   ├── backend/
│   │   ├── server.js                 # Express API server
│   │   ├── database.js               # SQLite setup
│   │   ├── routes/                   # API endpoints
│   │   ├── .env.example              # Config template
│   │   └── package.json              # Dependencies
│   └── frontend/
│       ├── login.html                # Login/register page
│       ├── index.html                # Dashboard
│       ├── admin.html                # Admin panel
│       └── styles.css                # Styling
└── docs/
    ├── ARCHITECTURE.md               # System design
    ├── API.md                        # API documentation
    └── TROUBLESHOOTING.md            # Common issues
```

---

## Support

For detailed help:
- Check **README.md** for full documentation
- See **ARCHITECTURE.md** for system design
- Review **API.md** for endpoint details
- Check router logs: `/log print`
- Check backend logs: `npm logs`

---

**Created:** August 2026
**Version:** 1.0.0
**Status:** Production Ready
