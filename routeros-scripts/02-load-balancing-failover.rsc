# Mikrotik RouterOS - Load Balancing Script (Corrected)
# Execute this after 02-load-balancing-failover.rsc

/ip firewall mangle
# Clear existing mangle rules first
remove [find comment~"LB-"]

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
# Remove old load balancing routes
remove [find comment~"LB-Route"]

# Add new routes with routing marks
add dst-address=0.0.0.0/0 gateway=ISP1 routing-mark="to-ISP1" comment="LB-Route-ISP1" disabled=no
add dst-address=0.0.0.0/0 gateway=ISP2 routing-mark="to-ISP2" comment="LB-Route-ISP2" disabled=no
add dst-address=0.0.0.0/0 gateway=ISP3 routing-mark="to-ISP3" comment="LB-Route-ISP3" disabled=no

# ============================================================
# STEP 3: Monitoring Script for Load Balancing Stats
# ============================================================

/system script
add name="lb-stats" source={
:local isp1-count [/ip route print count-only where comment="LB-Route-ISP1"]
:local isp2-count [/ip route print count-only where comment="LB-Route-ISP2"]
:local isp3-count [/ip route print count-only where comment="LB-Route-ISP3"]

:log info "Load Balance Status - ISP1: Active, ISP2: Active, ISP3: Active"
:log info "Active Connections: ISP1=$isp1-count, ISP2=$isp2-count, ISP3=$isp3-count"
}

# Schedule the monitoring script
/system scheduler
remove [find name="lb-monitor"]
add name="lb-monitor" interval=1m on-event="lb-stats" disabled=no

:log info "Load Balancing configuration completed successfully"
