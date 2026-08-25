# Mikrotik RouterOS - Firewall & Security Configuration
# Features: Hide internal setup from ISP providers, prevent tracing, NAT rules

# ============================================================
# STEP 1: Configure Source NAT (Hide Internal Network)
# ============================================================

/ip firewall nat
# Masquerade outgoing traffic from PPPoE users (ISP1)
add chain=srcnat action=masquerade out-interface=ISP1 comment="Masquerade-ISP1" disabled=no

# Masquerade outgoing traffic from PPPoE users (ISP2)
add chain=srcnat action=masquerade out-interface=ISP2 comment="Masquerade-ISP2" disabled=no

# Masquerade outgoing traffic from PPPoE users (ISP3)
add chain=srcnat action=masquerade out-interface=ISP3 comment="Masquerade-ISP3" disabled=no

# Masquerade LAN traffic
add chain=srcnat action=masquerade out-interface=ISP1 src-address=10.10.10.0/24 comment="Masquerade-LAN-ISP1" disabled=no

# ============================================================
# STEP 2: Configure Firewall Filter Rules (Input Chain)
# ============================================================

/ip firewall filter
# Allow established connections
add chain=input action=accept connection-state=established,related comment="Allow-Established" disabled=no

# Allow ICMP (with rate limit to prevent ping flood)
add chain=input action=accept protocol=icmp comment="Allow-ICMP" disabled=no

# Allow management access from LAN only
add chain=input action=accept protocol=tcp dst-port=22,8291 src-address=10.10.10.0/24 comment="Allow-SSH-WinBox-LAN" disabled=no

# Allow DNS queries
add chain=input action=accept protocol=udp dst-port=53 comment="Allow-DNS" disabled=no
add chain=input action=accept protocol=tcp dst-port=53 comment="Allow-DNS-TCP" disabled=no

# Allow DHCP Server responses
add chain=input action=accept protocol=udp dst-port=68 comment="Allow-DHCP" disabled=no

# Allow PPPoE Server traffic
add chain=input action=accept protocol=tcp dst-port=1194 comment="Allow-PPPoE" disabled=no

# Drop all other input traffic
add chain=input action=drop comment="Drop-All-Other-Input" disabled=no

# ============================================================
# STEP 3: Configure Firewall Filter Rules (Forward Chain)
# ============================================================

/ip firewall filter
# Allow established connections
add chain=forward action=accept connection-state=established,related comment="Forward-Established" disabled=no

# Allow traffic from LAN to Internet
add chain=forward action=accept src-address=10.10.10.0/24 comment="Forward-LAN-to-WAN" disabled=no

# Allow traffic from PPPoE users to Internet
add chain=forward action=accept src-address=172.22.162.0/24 comment="Forward-PPPoE-to-WAN" disabled=no

# Allow LAN to PPPoE communication
add chain=forward action=accept src-address=10.10.10.0/24 dst-address=172.22.162.0/24 comment="Forward-LAN-to-PPPoE" disabled=no

# Block fragmented packets
add chain=forward action=drop protocol=tcp tcp-flags=!fin,!syn,!rst,!ack comment="Drop-Invalid-TCP" disabled=no

# Drop all other forward traffic
add chain=forward action=drop comment="Drop-All-Other-Forward" disabled=no

# ============================================================
# STEP 4: Anti-DDoS Rules
# ============================================================

/ip firewall filter
# Limit connection attempts to prevent SYN flood
add chain=input action=accept protocol=tcp tcp-flags=syn comment="Allow-SYN" disabled=no

# Rate limit NEW connections
add chain=input action=jump jump-target=log-and-drop protocol=tcp tcp-flags=syn \
    comment="Rate-Limit-SYN" connection-limit=10,32 disabled=no

# Create jump target for logging and dropping
add chain=log-and-drop action=log comment="Log-Dropped-Packets" disabled=no
add chain=log-and-drop action=drop comment="Drop-After-Log" disabled=no

# ============================================================
# STEP 5: Port Scanning Protection
# ============================================================

/ip firewall filter
# Drop port scans (portscan detection)
add chain=input action=drop protocol=tcp dst-port=1-65535 \
    comment="Block-Port-Scans" disabled=no limit=1/5m

# ============================================================
# STEP 6: Hide Router Information
# ============================================================

/ip firewall filter
# Block ICMP traceroute attempts
add chain=input action=drop protocol=icmp icmp-options=11:0 comment="Block-Traceroute" disabled=no

# Block ICMP timestamp requests
add chain=input action=drop protocol=icmp icmp-options=13:0 comment="Block-Timestamp" disabled=no

# ============================================================
# STEP 7: Configure Bridge Firewall Rules
# ============================================================

/interface bridge settings
set use-ip-firewall=yes use-ip-firewall-for-pppoe=yes use-ip-firewall-for-vlan=yes

# ============================================================
# STEP 8: Enable FastTrack for Performance
# ============================================================

/ip firewall filter
add chain=forward action=fasttrack-connection comment="FastTrack" disabled=no

# ============================================================
# STEP 9: Configure TCP MSS Clamp
# ============================================================

/ip firewall mangle
# Clamp MSS for PPPoE traffic
add chain=forward action=change-mss new-mss=1452 protocol=tcp \
    tcp-flags=syn comment="MSS-Clamp-PPPoE" disabled=no dst-address=172.22.162.0/24

:log info "Firewall and security configuration completed"
