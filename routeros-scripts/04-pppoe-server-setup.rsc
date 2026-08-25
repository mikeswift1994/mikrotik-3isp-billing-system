# Mikrotik RouterOS - PPPoE Server Configuration (FULLY CORRECTED)
# Features: PPPoE profiles with speed limits (20/30/50/100/200/500 Mbps)
# Note: Backend queues will enforce actual speeds for speedtest.net

# ============================================================
# STEP 1: Create IP Address Pools for PPPoE
# ============================================================

/ip pool
add name="pppoe-pool-20mbps" ranges=172.22.162.100-172.22.162.110 comment="IP Pool 20Mbps"
add name="pppoe-pool-30mbps" ranges=172.22.162.111-172.22.162.130 comment="IP Pool 30Mbps"
add name="pppoe-pool-50mbps" ranges=172.22.162.131-172.22.162.155 comment="IP Pool 50Mbps"
add name="pppoe-pool-100mbps" ranges=172.22.162.156-172.22.162.175 comment="IP Pool 100Mbps"
add name="pppoe-pool-200mbps" ranges=172.22.162.176-172.22.162.195 comment="IP Pool 200Mbps"
add name="pppoe-pool-500mbps" ranges=172.22.162.196-172.22.162.210 comment="IP Pool 500Mbps"

# ============================================================
# STEP 2: Create PPP Profiles with IP Pools
# ============================================================

/ppp profile
add name="ppp-20mbps" local-address=172.22.162.1 address-pool=pppoe-pool-20mbps comment="PPPoE Profile 20Mbps"
add name="ppp-30mbps" local-address=172.22.162.1 address-pool=pppoe-pool-30mbps comment="PPPoE Profile 30Mbps"
add name="ppp-50mbps" local-address=172.22.162.1 address-pool=pppoe-pool-50mbps comment="PPPoE Profile 50Mbps"
add name="ppp-100mbps" local-address=172.22.162.1 address-pool=pppoe-pool-100mbps comment="PPPoE Profile 100Mbps"
add name="ppp-200mbps" local-address=172.22.162.1 address-pool=pppoe-pool-200mbps comment="PPPoE Profile 200Mbps"
add name="ppp-500mbps" local-address=172.22.162.1 address-pool=pppoe-pool-500mbps comment="PPPoE Profile 500Mbps"

# ============================================================
# STEP 3: Configure PPPoE Server Interface
# ============================================================

/interface pppoe-server
# Check if interface exists first: /interface pppoe-server print
# If it doesn't exist, uncomment and run:
# add name=PPPoE-Server disabled=no

# ============================================================
# STEP 4: Configure PPPoE Server Settings
# ============================================================

/interface pppoe-server server
reset
set enabled=yes authentication=pap,chap default-profile=ppp-20mbps interface=PPPoE-Server

# ============================================================
# STEP 5: Create PPPoE Secrets (Users)
# ============================================================

/ppp secret
# Add test users - replace with actual user data from billing system
add name="user1@20mbps" password="pass123" service=pppoe profile=ppp-20mbps
add name="user2@30mbps" password="pass123" service=pppoe profile=ppp-30mbps
add name="user3@50mbps" password="pass123" service=pppoe profile=ppp-50mbps
add name="user4@100mbps" password="pass123" service=pppoe profile=ppp-100mbps
add name="user5@200mbps" password="pass123" service=pppoe profile=ppp-200mbps
add name="user6@500mbps" password="pass123" service=pppoe profile=ppp-500mbps

# ============================================================
# STEP 6: Configure Queue Simple for Speed Limiting
# (Simpler than Queue Tree and more reliable for PPPoE)
# ============================================================

/queue simple
# Remove old queues if they exist
:do { remove [find comment~"Queue-"] } on-error={}

# Add simple queues for each speed tier based on IP pools
add target=172.22.162.100-172.22.162.110 max-limit=20M/20M comment="Queue-20Mbps"
add target=172.22.162.111-172.22.162.130 max-limit=30M/30M comment="Queue-30Mbps"
add target=172.22.162.131-172.22.162.155 max-limit=50M/50M comment="Queue-50Mbps"
add target=172.22.162.156-172.22.162.175 max-limit=100M/100M comment="Queue-100Mbps"
add target=172.22.162.176-172.22.162.195 max-limit=200M/200M comment="Queue-200Mbps"
add target=172.22.162.196-172.22.162.210 max-limit=500M/500M comment="Queue-500Mbps"

# ============================================================
# STEP 7: Configure IP Address for PPPoE Server Interface
# ============================================================

/ip address
# Check if address already exists
:do { add address=172.22.162.1/24 interface=PPPoE-Server comment="PPPoE-Server-Address" } on-error={}

# ============================================================
# STEP 8: Configure DNS for PPPoE Clients
# ============================================================

/ip dns
set servers=8.8.8.8,8.8.4.4 allow-remote-requests=yes cache-size=2048 cache-max-ttl=1w

# ============================================================
# STEP 9: Configure Routing for PPPoE Clients
# ============================================================

/ip route
# Ensure PPPoE pool subnet is routed through PPPoE server
:do { add dst-address=172.22.162.0/24 gateway=172.22.162.1 comment="PPPoE-Network" } on-error={}

# ============================================================
# STEP 10: Enable PPP Logging
# ============================================================

/system logging
:do { remove [find topics~"ppp"] } on-error={}
add topics=ppp action=memory

# ============================================================
# STEP 11: Enable PPP Event Monitoring
# ============================================================

/system logging
add topics=ppp,info action=echo prefix="[PPP] "

# ============================================================
# VERIFICATION COMMANDS
# ============================================================

:log info "PPPoE Server configuration COMPLETED successfully"
:log info "Created 6 speed profiles with separate IP pools"
:log info "Speed limits enforced via Queue Simple: 20/30/50/100/200/500 Mbps"
:log info ""
:log info "NEXT STEPS:"
:log info "1. Verify pools: /ip pool print"
:log info "2. Verify profiles: /ppp profile print"
:log info "3. Verify server: /interface pppoe-server server print"
:log info "4. Verify users: /ppp secret print"
:log info "5. Verify queues: /queue simple print"
:log info "6. Test connection from PPPoE client"
:log info "7. Test speed: speedtest-cli should show configured limit"
