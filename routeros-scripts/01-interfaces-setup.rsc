# Mikrotik RouterOS - Interface Configuration Script
# Setup: 3 ISPs (ether1, ether2, ether3) + PPPoE Server (ether4) + LAN (ether5)

# ============================================================
# STEP 1: Configure ISP Interfaces (Ether 1, 2, 3)
# ============================================================

# ISP 1 - Ether 1
/interface ethernet
set ether1 name="ISP1" mtu=1500 l2mtu=1598

# ISP 2 - Ether 2
set ether2 name="ISP2" mtu=1500 l2mtu=1598

# ISP 3 - Ether 3
set ether3 name="ISP3" mtu=1500 l2mtu=1598

# ============================================================
# STEP 2: Configure IP Addresses for ISPs (DHCP)
# ============================================================

/ip address
# ISP1 - Ether1 (DHCP)
add address=0.0.0.0 interface=ISP1 disabled=no

# ISP2 - Ether2 (DHCP)
add address=0.0.0.0 interface=ISP2 disabled=no

# ISP3 - Ether3 (DHCP)
add address=0.0.0.0 interface=ISP3 disabled=no

# ============================================================
# STEP 3: Configure DHCP Clients for ISPs
# ============================================================

/ip dhcp-client
# ISP1
add interface=ISP1 disabled=no

# ISP2
add interface=ISP2 disabled=no

# ISP3
add interface=ISP3 disabled=no

# ============================================================
# STEP 4: Configure PPPoE Server Interface (Ether 4)
# ============================================================

/interface ethernet
set ether4 name="PPPoE-Server" mtu=1500 l2mtu=1598

# Add IP Address for PPPoE Server
/ip address
add address=172.22.162.1/24 interface=PPPoE-Server disabled=no

# ============================================================
# STEP 5: Configure LAN Interface (Ether 5)
# ============================================================

/interface ethernet
set ether5 name="LAN" mtu=1500 l2mtu=1598

# Add IP Address for LAN
/ip address
add address=10.10.10.1/24 interface=LAN disabled=no

# ============================================================
# STEP 6: Create Bridge for Internal Network (Optional)
# ============================================================

/interface bridge
add name=bridge-local protocol-mode=rstp

# Add LAN to bridge
/interface bridge port
add interface=LAN bridge=bridge-local

# ============================================================
# STEP 7: Configure DHCP Server for LAN
# ============================================================

/ip pool
add name=dhcp-pool ranges=10.10.10.100-10.10.10.254

/ip dhcp-server
add name=dhcp-lan interface=LAN address-pool=dhcp-pool disabled=no

/ip dhcp-server network
add address=10.10.10.0/24 gateway=10.10.10.1 dns-server=8.8.8.8,8.8.4.4 netmask=24

:log info "Interface configuration completed successfully"
