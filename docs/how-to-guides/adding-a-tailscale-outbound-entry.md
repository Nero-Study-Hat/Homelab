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

For mac address generation I used: [Random MAC Address Generator](https://www.hellion.org.uk/cgi-bin/randmac.pl)
The mac addresses I use are
- LAA
- Unicast
- Randomized MAC
    - "a privacy technique whereby mobile devices rotate through random hardware addresses in order to prevent observers from singling out their traffic or physical location from other nearby devices"