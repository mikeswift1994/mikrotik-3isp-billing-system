# Mikrotik RouterOS - PPPoE Server Configuration
# Features: PPPoE profiles with speed limits (20/30/50/100/200/500 Mbps)
# Note: Backend queues will enforce actual speeds for speedtest.net

# ============================================================
# STEP 1: Configure PPP Settings
# ============================================================

/ppp
set max-packet-queue=100

# ============================================================
# STEP 2: Create PPP Profiles with Bandwidth Limits
# ============================================================

/ppp profile
# Profile: 20 Mbps
add name="ppp-20mbps" local-address=172.22.162.1 remote-address=172.22.162.100-172.22.162.150 \
    rate-limit=20M/20M comment="PPPoE Profile 20Mbps" disabled=no

# Profile: 30 Mbps
add name="ppp-30mbps" local-address=172.22.162.1 remote-address=172.22.162.151-172.22.162.200 \
    rate-limit=30M/30M comment="PPPoE Profile 30Mbps" disabled=no

# Profile: 50 Mbps
add name="ppp-50mbps" local-address=172.22.162.1 remote-address=172.22.162.201-172.22.162.225 \
    rate-limit=50M/50M comment="PPPoE Profile 50Mbps" disabled=no

# Profile: 100 Mbps
add name="ppp-100mbps" local-address=172.22.162.1 remote-address=172.22.162.226-172.22.162.240 \
    rate-limit=100M/100M comment="PPPoE Profile 100Mbps" disabled=no

# Profile: 200 Mbps
add name="ppp-200mbps" local-address=172.22.162.1 remote-address=172.22.162.241-172.22.162.247 \
    rate-limit=200M/200M comment="PPPoE Profile 200Mbps" disabled=no

# Profile: 500 Mbps
add name="ppp-500mbps" local-address=172.22.162.1 remote-address=172.22.162.248-172.22.162.254 \
    rate-limit=500M/500M comment="PPPoE Profile 500Mbps" disabled=no

# ============================================================
# STEP 3: Configure PPPoE Server
# ============================================================

/interface pppoe-server server
set enabled=yes authentication=pap,chap default-profile=ppp-20mbps interface=PPPoE-Server

# ============================================================
# STEP 4: Create PPPoE Secrets (Users)
# ============================================================

/ppp secret
# Example users with their assigned profiles
add name="user1@20mbps" password="pass123" service=pppoe profile=ppp-20mbps disabled=no
add name="user2@30mbps" password="pass123" service=pppoe profile=ppp-30mbps disabled=no
add name="user3@50mbps" password="pass123" service=pppoe profile=ppp-50mbps disabled=no
add name="user4@100mbps" password="pass123" service=pppoe profile=ppp-100mbps disabled=no
add name="user5@200mbps" password="pass123" service=pppoe profile=ppp-200mbps disabled=no
add name="user6@500mbps" password="pass123" service=pppoe profile=ppp-500mbps disabled=no

# ============================================================
# STEP 5: Configure Queue Trees for Speed Limiting
# (This enforces the REAL speeds for speedtest.net)
# ============================================================

/queue tree
# Queue for 20 Mbps profile
add name="queue-20mbps" parent=global-out packet-mark="" limit-at=20M \
    max-limit=20M burst-limit=20M burst-time=5s priority=8 comment="Queue-20Mbps" disabled=no

# Queue for 30 Mbps profile
add name="queue-30mbps" parent=global-out packet-mark="" limit-at=30M \
    max-limit=30M burst-limit=30M burst-time=5s priority=8 comment="Queue-30Mbps" disabled=no

# Queue for 50 Mbps profile
add name="queue-50mbps" parent=global-out packet-mark="" limit-at=50M \
    max-limit=50M burst-limit=50M burst-time=5s priority=8 comment="Queue-50Mbps" disabled=no

# Queue for 100 Mbps profile
add name="queue-100mbps" parent=global-out packet-mark="" limit-at=100M \
    max-limit=100M burst-limit=100M burst-time=5s priority=8 comment="Queue-100Mbps" disabled=no

# Queue for 200 Mbps profile
add name="queue-200mbps" parent=global-out packet-mark="" limit-at=200M \
    max-limit=200M burst-limit=200M burst-time=5s priority=8 comment="Queue-200Mbps" disabled=no

# Queue for 500 Mbps profile
add name="queue-500mbps" parent=global-out packet-mark="" limit-at=500M \
    max-limit=500M burst-limit=500M burst-time=5s priority=8 comment="Queue-500Mbps" disabled=no

# ============================================================
# STEP 6: Mark Packets by User Profile
# ============================================================

/ip firewall mangle
# Mark traffic from 20 Mbps users
add chain=postrouting action=mark-packet new-packet-mark="pkt-20mbps" passthrough=no \
    src-address=172.22.162.100-172.22.162.150 comment="Mark-20Mbps" disabled=no

# Mark traffic from 30 Mbps users
add chain=postrouting action=mark-packet new-packet-mark="pkt-30mbps" passthrough=no \
    src-address=172.22.162.151-172.22.162.200 comment="Mark-30Mbps" disabled=no

# Mark traffic from 50 Mbps users
add chain=postrouting action=mark-packet new-packet-mark="pkt-50mbps" passthrough=no \
    src-address=172.22.162.201-172.22.162.225 comment="Mark-50Mbps" disabled=no

# Mark traffic from 100 Mbps users
add chain=postrouting action=mark-packet new-packet-mark="pkt-100mbps" passthrough=no \
    src-address=172.22.162.226-172.22.162.240 comment="Mark-100Mbps" disabled=no

# Mark traffic from 200 Mbps users
add chain=postrouting action=mark-packet new-packet-mark="pkt-200mbps" passthrough=no \
    src-address=172.22.162.241-172.22.162.247 comment="Mark-200Mbps" disabled=no

# Mark traffic from 500 Mbps users
add chain=postrouting action=mark-packet new-packet-mark="pkt-500mbps" passthrough=no \
    src-address=172.22.162.248-172.22.162.254 comment="Mark-500Mbps" disabled=no

# ============================================================
# STEP 7: Assign Queue Rules to Marked Packets
# ============================================================

/queue tree
# Assign queues based on packet marks
set [find name="queue-20mbps"] packet-mark="pkt-20mbps"
set [find name="queue-30mbps"] packet-mark="pkt-30mbps"
set [find name="queue-50mbps"] packet-mark="pkt-50mbps"
set [find name="queue-100mbps"] packet-mark="pkt-100mbps"
set [find name="queue-200mbps"] packet-mark="pkt-200mbps"
set [find name="queue-500mbps"] packet-mark="pkt-500mbps"

# ============================================================
# STEP 8: Configure DNS for PPPoE Clients
# ============================================================

/ip dns
set servers=8.8.8.8,8.8.4.4 allow-remote-requests=yes

# ============================================================
# STEP 9: Enable PPP Logging
# ============================================================

/system logging
add topics=ppp action=memory

:log info "PPPoE Server configuration completed with 6 speed profiles"
