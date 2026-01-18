## traffic flow

### container flow
tailscale only wave out of docker network and vlan
container can be part of multiple docker networks ...
shared_networks ...
t3_networks ...
tailscale_networks ...
default networks ...

### user flow
device -> Gate:(nginx, dnsmasq, tailscale) -> Reverse Proxy:(traefik, dnsmasq, tailscale)


### physical data flow
#### Walkthrough from Modem to endpoint and back physically.
Details include ports used, speed of those ports, etc.