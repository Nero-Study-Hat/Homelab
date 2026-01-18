
This is going to be a write-up covering everything going on in my home network with the devices present, services run, security implemented, and everything yet to be implemented.

Let's begin with what I will have in my network and what I want from those things for context when we get into the security of it all.

In terms of straight hardware being used there will be two client PCs, four laptops, one very old Ipad, two android phones, one consumer grade router, one managed VLAN capable switch, two unmanaged switches, and one server box. Also the modem with the 1GB internet plan from my ISP.

An important note for how I will be working with these is that I am subsuming the existing family network whole into mine so the existing configuration of modem -> consumer grade router (WAP as well) -> clients (every device except one PC) will stay the same just put behind my router, OPNSense on the server box which is running the Proxmox Hypervisor.

The one PC not behind the family router will be mine and the server box with Proxmox will be running all my self hosted services also in different segments of the network.

The services I am running include
- Network Services
	- OPNSense
	- Suricata
	- Crowdsec
	- Pihole
	- Traefik
	- Tailscale
- Cloud Services
	- Nextcloud
	- Searxng

The services I plan to run additionally include
- Network Services
	- ProtonVPN
- Monitoring Services
	- Promotheseus
	- Grafana
	- (graylog or loki?)
- Cloud Services
	- Radicale
- Media Services
	- Jellyfin
	- Arr Stack

Now that attendance has been taken lets cover what everyone should be allowed and not allowed to do.

Nothing outside the family network (term for family consumer grade router and all devices behind) should be able to reach or interact with devices in the family network.

My personal LAN for clients should be isolated from every other network except for through Tailscale connections.

All my self hosted services should only be accessible through Tailscale with access permissions applied through ACLs and created users.

The media services should be unable to reach out to interact with any services beyond themselves and what is making them reachable. The same for my personal cloud services and a separate group of cloud services hosted for some friends of mine.

---

Alright, now that it's clear what I am working with and what I want from it all lets get into how I am making this work.

The first major layer of security is my router OPNSense which will have VLANs configured for segmenting the network into the above groups, with a deny all approach in the rules for each VLAN (except the family VLAN) with specific rules for allowed traffic.

I am leaving the family VLAN with a basic allow all from their VLAN NET to any destination and blocking private address traffic not in their subnet because with my Dad's work, I am not sure just what he may need to reach and don't want to have to always be on call with a possibly large amount of urgency to resolve the issue. Plus, I don't want to create friction for him as a whole. I may change my mind here later.

Aside from the rules and VLAN configuration I some IDS and IPS implemented.

There is Crowdsec which parses the firewall logs and based off its findings declares whether the incoming traffic is malicious or not. It is also notably blocking traffic to/from IPs on their blacklist which is developed collaboratively by everyone using it. When Crowdsec detects an attack is sends only the attack details out to Crowdsec which then used by everyone else using Crowdsec so that when one user is attacked, other can benefit from that intelligence. The privacy risk is very low as the data collected is for a detected attack with minimal details for that. I haven't done anymore configuration that with it for now including log monitoring accessing their dashboard.

There is Suricata for inspecting traffic that has passed through my LAN interface with the rules there. It will actively look through the packets passing through the router at the interfaces it is set to listen on and send off alerts or alert and drop the packets based on rulesets installed and enabled. I have the ET-Telemetry rulesets installed and enabled minus a few that are likely to lead to much slower internet and many false positives. This ruleset is kept very update with vulnerabilities being found and is free with the caveat of sending the alerts to the maintainers so they can improve their rulesets. No actual traffic data is recorded.

Additional note: I plan to configure Crowdsec to take advantage of my Suricata logs as well.

I know with modern adoption of encrypted traffic, Suricata is not as useful as it once was because it can't see into the packets clearly for pattern matching the traffic and it brings more maintenance to the setup with false positives. Even still, it can act as another layer in my defense and stop a certain level of low hanging fruit attacks from pwning me. Similarly the IP blocking of known malicious addresses from Suricata and Crowdsec is limited with the consideration of single IP addresses covering lots of different good and bad services, only being aware of addresses responsible for already making attacks, and proxying technology being used. This makes another layer of defense in my network against the attacks going for the low hanging fruit.

Management of my router has been improved by creating a new user with admin privileges and disabling the root user. This new user requires 2FA for login with the Yubico Authenticator app connected to my personal Yubikey and the base password has all character types at a 13+ count. The web interface can only be accessed from my LAN interface where my personal client devices are (all wired) and SSH is access is disabled. The web interface has SSL using the ACME plugin and my custom domain with Desec.

---

The next major layer of defense is my Tailscale and Traefik (reverse proxy) setup.

I am using the Tailscale overlay VPN to
- provide ssh access to servers in a different vlan (one-way)
- make all my docker services available for users
- provide dns for users using my docker services

The way I do this is with the ACL file in Tailscale for managing what can reach what and how, tags for automated server identification in the ACL file, and split DNS for my subdomains to be used on user devices.

I have a `ssh-server` tag for my proxmox vms which is setup using cloud-init. In the ACL file I allow my personal dev machine to use tcp on port 22 -> a Tailscale machine with this tag.

I have tags for my different servers (cloud, fog, media) which are used for Tailscale docker containers to auto approve them to advertise a subnet (specific to the server tag) defined in the ACL file.

There are a few rules (grants in Tailscale) which I use here. The first set are for the split-DNS setup which involves different Dnsmaq instances for different Tailscale machines.
- users -> user-dns
- nginx -> nginx-dns
- cloud-subnet -> cloud-dns
- fog-subnet -> fog-dns
- media-subnet -> media-dns

Then I force users to only be allowed to reach the NGINX instance which is then only allowed to reach the Traefik instances. I do this because it forces users to go through Traefik to reach end services and still gives me the ability to filter what specific users get access to while blocking their access to all the services directly. In the case where I need to access service manually over the tailnet I can always add another temporary rule allowing traffic from my dev machine directly to the service I need a direct connection to.

Another part of my Tailscale setup is the accounts I created for two additional users in my tailnet. These are  


I have three Tailscale accounts setup including a main account whose tailnet holds all the devices I am connecting, a media account for giving to people for media services access, and a cloud account for giving to people for cloud service access (not my personal cloud). Inviting users has been set to require approvals for that specific user so just having an invite link is not enough.

The devices on my tailnet include my PC, my laptop, my personal cloud, shared cloud, and shared media services. I plan to bring more devices into my network once I have it completed by sharing the media and cloud user accounts for people to authenticate their devices into my tailnet with permissions already setup.

Aside from identifying devices with users using the aforementioned accounts there are tags I have made for identifying the servers I am running. The tags include `ssh-server`,`personal-cloud-server`,`cloud-server`, and `media-server`. These tags are used on server/service initialization to automatically log into my tailnet with the appropriate identity and permissions.

Now lets get into the ACLs where the permissions are defined.

The `ssh-server` tag is used for allowing devices on the tailnet with my main account user to ssh into machines on the tailnet with this tag. To give context for this, my configuration approach for everything is centered around IaC with as little manual intervention as possible. I have cloud init template in my Proxmox instance which initializes VMs with this tag. This way when a server VM is created in a separate VLAN from my development PC using Terraform with no direct access route in the network, I can still reach out using Tailscale ssh for Ansible to configure the server.

The following three tags are used for the `autoApprovers` block in Tailscale which I use to advertise specific subnets where I will be running docker services. This way I don't need manually approve the specific subnet advertisements from Tailscale instances with the appropriate tag. This is the simplest way I found to expose my services and I can setup traffic rules for the subnets with this now too.

So now lets get into what traffic I am allowing where.
If you don't see it allowed, it's not. The * stands for any port.

From devices authenticated with the main account
-> ssh-server:22
-> personal-cloud-subnet:*
-> media-subnet:*
-> cloud-subnet:*

From devices authenticated with the cloud account
-> cloud-subnet:*

From devices authenticated with the media account
-> media-subnet:*

There is a lot more for me to add here in the future which I discuss later in my plans for extending this setup. For now this covers the important bases I care about nicely.

In regards to accessing services on my tailnet, I have turned off MagicDNS and setup a self hosted Pihole DNS server in my tailnet which is set as a split-DNS custom server in my Tailscale settings. This way on my custom domain requests go to this DNS server which points to the appropriate reverse proxy instance and leads to the requested service.

Tailscale HTTPS Certificates are not being used with this feature disabled as I am handling SSL for my personal domain with Traefik, Acme, Desec, and Let's Encrypt. The only middleware I am currently using in Traefik is `traefik-auth` for accessing the dashboard and `traefik-https-redirect` for HTTP to HTTPS redirect.

The device approval feature which requires new devices in the tailnet is off currently and will be turned on once my setup is stable.

All in development tailscale features are not being used currently as I have no need for them.

More work I have planned for this setup includes
- migrating from ACLs which are considered deprecated in favor of grants
- replacing my main user account that is github based to one that is yubikey passkey based
- setting up tests and posture checks in the ACL file
- changing all my ts-auth keys to no longer be re-usable once my setup is stable.
- setting up Crowdsec on my Traefik instances in conjunction with the main instance on my router
I might setup ACL file management through gitops as well and I want to look into additional middleware I may be interested in for Traefik.

---

Then there are a few more planned major layers of defense I don't have fully or at all setup yet.

Another major layer of defense is endpoint security with update management.


The final major layer of defense I have planned currently is breach detection combined with my ability to easily to take down and re-up my self hosting machines and services.



---

What vulnerabilities do I still feel I have
- brute force attack: my hardware will be overwhelmed





---
Additional improvements I could make here include
- offline service usage in LAN capability
