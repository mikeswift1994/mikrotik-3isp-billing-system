# Mikrotik RouterOS - PPPoE Server Configuration (CORRECTED)
# Features: PPPoE profiles with speed limits (20/30/50/100/200/500 Mbps)
# Note: Backend queues will enforce actual speeds for speedtest.net

# ============================================================
# STEP 1: Create PPP Profiles with Bandwidth Limits
# ============================================================

/ppp profile
add name="ppp-20mbps" local-address=172.22.162.1 remote-address=172.22.162.100-172.22.162.150 comment="PPPoE Profile 20Mbps"
add name="ppp-30mbps" local-address=172.22.162.1 remote-address=172.22.162.151-172.22.162.200 comment="PPPoE Profile 30Mbps"
add name="ppp-50mbps" local-address=172.22.162.1 remote-address=172.22.162.201-172.22.162.225 comment="PPPoE Profile 50Mbps"
add name="ppp-100mbps" local-address=172.22.162.1 remote-address=172.22.162.226-172.22.162.240 comment="PPPoE Profile 100Mbps"
add name="ppp-200mbps" local-address=172.22.162.1 remote-address=172.22.162.241-172.22.162.247 comment="PPPoE Profile 200Mbps"
add name="ppp-500mbps" local-address=172.22.162.1 remote-address=172.22.162.248-172.22.162.254 comment="PPPoE Profile 500Mbps"

# ============================================================
# STEP 2: Configure PPPoE Server Interface
# ============================================================

/interface pppoe-server
# Interface may already exist, check first with /interface pppoe-server print
# If it doesn't exist, add it:
# add name=PPPoE-Server disabled=no

# ============================================================
# STEP 3: Configure PPPoE Server Settings
# ============================================================

/interface pppoe-server server
reset
set enabled=yes authentication=pap,chap default-profile=ppp-20mbps interface=PPPoE-Server

# ============================================================
# STEP 4: Create PPPoE Secrets (Users)
# ============================================================

/ppp secret
# First clear existing secrets or add new ones
add name="user1@20mbps" password="pass123" service=pppoe profile=ppp-20mbps
add name="user2@30mbps" password="pass123" service=pppoe profile=ppp-30mbps
add name="user3@50mbps" password="pass123" service=pppoe profile=ppp-50mbps
add name="user4@100mbps" password="pass123" service=pppoe profile=ppp-100mbps
add name="user5@200mbps" password="pass123" service=pppoe profile=ppp-200mbps
add name="user6@500mbps" password="pass123" service=pppoe profile=ppp-500mbps

# ============================================================
# STEP 5: Configure Queue Simple for Speed Limiting
# (Alternative to Queue Tree - simpler and more reliable)
# ============================================================

/queue simple
# Remove old queues if they exist
:do { remove [find comment~"Queue-"] } on-error={}

# Add new simple queues for each speed tier
add target=172.22.162.100-172.22.162.150 max-limit=20M/20M comment="Queue-20Mbps"
add target=172.22.162.151-172.22.162.200 max-limit=30M/30M comment="Queue-30Mbps"
add target=172.22.162.201-172.22.162.225 max-limit=50M/50M comment="Queue-50Mbps"
add target=172.22.162.226-172.22.162.240 max-limit=100M/100M comment="Queue-100Mbps"
add target=172.22.162.241-172.22.162.247 max-limit=200M/200M comment="Queue-200Mbps"
add target=172.22.162.248-172.22.162.254 max-limit=500M/500M comment="Queue-500Mbps"

# ============================================================
# STEP 6: Mark Packets by User Profile (Optional)
# ============================================================

/ip firewall mangle
# Remove old mangle rules
:do { remove [find comment~"Mark-"] } on-error={}

# Mark traffic from different user tiers for monitoring
add chain=postrouting action=mark-packet new-packet-mark="pkt-20mbps" passthrough=no src-address=172.22.162.100-172.22.162.150 comment="Mark-20Mbps"
add chain=postrouting action=mark-packet new-packet-mark="pkt-30mbps" passthrough=no src-address=172.22.162.151-172.22.162.200 comment="Mark-30Mbps"
add chain=postrouting action=mark-packet new-packet-mark="pkt-50mbps" passthrough=no src-address=172.22.162.201-172.22.162.225 comment="Mark-50Mbps"
add chain=postrouting action=mark-packet new-packet-mark="pkt-100mbps" passthrough=no src-address=172.22.162.226-172.22.162.240 comment="Mark-100Mbps"
add chain=postrouting action=mark-packet new-packet-mark="pkt-200mbps" passthrough=no src-address=172.22.162.241-172.22.162.247 comment="Mark-200Mbps"
add chain=postrouting action=mark-packet new-packet-mark="pkt-500mbps" passthrough=no src-address=172.22.162.248-172.22.162.254 comment="Mark-500Mbps"

# ============================================================
# STEP 7: Configure IP Address for PPPoE Server
# ============================================================

/ip address
# Check if address already exists before adding
:do { add address=172.22.162.1/24 interface=PPPoE-Server comment="PPPoE-Server-Address" } on-error={}

# ============================================================
# STEP 8: Configure DNS for PPPoE Clients
# ============================================================

/ip dns
set servers=8.8.8.8,8.8.4.4 allow-remote-requests=yes cache-size=2048 cache-max-ttl=1w

# ============================================================
# STEP 9: Enable PPP Logging
# ============================================================

/system logging
:do { remove [find topics~"ppp"] } on-error={}
add topics=ppp action=memory

# ============================================================
# STEP 10: Verify Configuration
# ============================================================

:log info "PPPoE Server configuration completed"
:log info "Profiles created: 6 speed tiers (20/30/50/100/200/500 Mbps)"
:log info "Server enabled: Check with /interface pppoe-server print"
:log info "Test connection: telnet 172.22.162.1"
