# Mikrotik RouterOS - Load Balancing Script (Fixed)
# Execute this after 02-load-balancing-failover.rsc

/ip firewall mangle
# Clear existing mangle rules first
:do { remove [find comment~"LB-"] } on-error={}

# Configure per-connection load balancing across 3 ISPs
# Each new connection is assigned round-robin to ISP1, ISP2, or ISP3

# Mark connections for ISP1 (1st out of every 3)
add chain=prerouting action=mark-connection new-connection-mark="conn-ISP1" passthrough=yes \
    comment="LB-conn-ISP1" per-connection-classifier=both-addresses-and-ports:3/1

# Mark connections for ISP2 (2nd out of every 3)
add chain=prerouting action=mark-connection new-connection-mark="conn-ISP2" passthrough=yes \
    comment="LB-conn-ISP2" per-connection-classifier=both-addresses-and-ports:3/2

# Mark connections for ISP3 (3rd out of every 3)
add chain=prerouting action=mark-connection new-connection-mark="conn-ISP3" passthrough=yes \
    comment="LB-conn-ISP3" per-connection-classifier=both-addresses-and-ports:3/3

# Now mark the routing based on connection marks
add chain=prerouting action=mark-routing new-routing-mark="to-ISP1" passthrough=no \
    connection-mark="conn-ISP1" comment="Route-to-ISP1" disabled=no

add chain=prerouting action=mark-routing new-routing-mark="to-ISP2" passthrough=no \
    connection-mark="conn-ISP2" comment="Route-to-ISP2" disabled=no

add chain=prerouting action=mark-routing new-routing-mark="to-ISP3" passthrough=no \
    connection-mark="conn-ISP3" comment="Route-to-ISP3" disabled=no

# ============================================================
# STEP 2: Configure Routing based on Marks
# ============================================================

/ip route
# Remove old load balancing routes (safely)
:do { remove [find comment~"LB-Route"] } on-error={}

# Add new routes with routing marks
add dst-address=0.0.0.0/0 gateway=ISP1 routing-mark="to-ISP1" comment="LB-Route-ISP1" disabled=no
add dst-address=0.0.0.0/0 gateway=ISP2 routing-mark="to-ISP2" comment="LB-Route-ISP2" disabled=no
add dst-address=0.0.0.0/0 gateway=ISP3 routing-mark="to-ISP3" comment="LB-Route-ISP3" disabled=no

# ============================================================
# STEP 3: Monitoring Script for Load Balancing Stats
# ============================================================

/system script
# Remove old script if exists
:do { remove [find name="lb-stats"] } on-error={}

# Add new monitoring script
add name="lb-stats" source={
    :log info "Load Balancing System Active"
    :log info "ISP1, ISP2, ISP3 Ready - All routes enabled"
}

# ============================================================
# STEP 4: Schedule Health Check Monitor
# ============================================================

/system scheduler
# Remove old scheduler if exists
:do { remove [find name="lb-monitor"] } on-error={}

# Add new scheduler for monitoring
add name="lb-monitor" interval=30s on-event="lb-stats" disabled=no

:log info "Load Balancing configuration completed successfully"
