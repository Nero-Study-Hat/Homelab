### firewall group
- SERVERS: contain all vlans listed below

### vlans
- Day
- Day_Network_Center
- Day_User_Gateway
- Day_Monitor_Center
- Day_Edgeshark

- Dusk

- Night
- Night_Network_Center
- Night_Monitor_Outpost
- Night_Edgeshark

### firewall rules - servers group
- allow IPv4 UDP in src SERVERS net -> any @ port 53 (DNS)
- allow IPv4 TCP in src SERVERS net -> any @ port 80 443 (HTTP/HTTPS)
- allow IPv4 UDP in src SERVERS net -> any @ port 123 (NTP)
- allow IPv4 ICMP in src SERVERS net -> any

### checklist for adding a tailscale outbound entry
- interfaces
    - create a new vlan device with a name vlan0.tag_number
        - make sure the parent device is corrent
    - assign the interface with proper prefix
        - don't skimp on name length because changing later is a pain
    - go to the created interface
        - enable and create /29 network with block bogon static ipv4
- dhcp
    - enable dhcp server and set the dhcp pool as last 2 addresses
    - add two static mappings, one for server and one for container
- firewall
    - go to groups and add the created interface to the servers group