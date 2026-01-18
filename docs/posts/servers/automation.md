# Automation

> [!important] 
> ***What this document is and is not.***
> 
> The purpose of this doc to help me is to onboard someone to working with the project IaC by
> - walking through the full deployment and configuration workflow
> 	- explaining how new server nodes are made
> 	- explaining how new server nodes are configured
> - explaining the purpose of each ansible role
> - explaining what my IaC *currently* achieves regarding the operational needs of my Homelab

---
## How New Server Nodes Are Made

> [!note] 
> Servers are separated by risk factor in my Homelab.
> 
> The current servers are Day, Dusk, Night for very low safe, medium risk, high danger.

1. Decide how they fit my networking schemas.
> See: [Network Setup](.././network/main.md)

1. Handle OPNSense and Tailscale configuration.

2. Choose the Cloud Init option, default `tailscale_based` unless there are issue with Tailscale.

3. In Proxmox create a Template using the Cloud Init snippet Debian 12 image from the internet.
 
> [!tip] 
> In the future image management should be specially handled but for now I am approaching this most simply.

5. In Proxmox update the `vlan_interfaces` file to prepare the required network interface for the server node.

6. Create a Terraform project directory for that server node using `mkdir` and `terraform init`. Fill in the `main.tf` file.

> [!tip] 
> Separate directories are used instead of
> - Terraform Workspaces here because the configuration can differ for the network interfaces used. Not just var value differences.
> - One directory with modules because server are not always deployed and worked with together.

7. Use the command `terraform apply` to create the server node.


## How Server Nodes Are Configured

1. Add a new entry to the `hosts.yaml` file in the Ansible Inventory directory in this repository.

2. Create a new playbook file in the Ansible Playbooks directory in this repository.

3. In the relevant playbook file load my secrets using `sops` with the `community.sops.load_vars` Ansible module.

4. Add to the relevant playbook file `include_role` tasks in the below order. I discuss what each role group is in the upcoming sub-section.
	1. Blanket Roles Group
	2. Special Roles Group
	3. End Service Roles Group

> [!important] 
> Roles and in turn Host Var files are built and updated using my Service Config Generator Tool. For learning about this part of the process go to the tool repository's docs.
> > https://github.com/Nero-Study-Hat/Homelab-Tools/tree/main/service_config_generator

5. Use the below command to run the relevant playbook.
	1. `ansible-playbook -i inventory/hosts.yaml playbooks/{host_name}_deploy.yaml`

### Ansible Roles In the Project

### Blanket Roles
> roles that are: added to all servers initial configuration for operational purposes

#### `debian_server`

This uses the `geerlingguy.swap` external role.

Responsibilities
- handle `resolveconf` DNS setup
- handle swap
- handle data directory on HDD

#### `local_dns`

This is never used directly in an Ansible playbook. Instead it is used by particular Ansible roles. To so more about my DNS setup and the decisions made there here are my network docs.
> [Network Docs](.././network)

Responsibilities
- deploy `dnsmasq` instance
- provide DNS records for private addresses in isolated docker networks

#### `network_center`

Responsibilities
- provide main Traefik instance that almost if not all services on a given server use
- advertise subnets for Tailnet
- provide Tailscale DNS `dnsmasq` instance

#### Special Roles
> roles that are: added only to particular servers for operational purposes

#### `nginx_gate`

Responsibilities
- proxy user to end service traffic through Tailnet. `dnsmasq` & `nginx`
- filter what services given users can access in the Tailnet

To learn more about traffic flow and how that is being handled look at
> [Traffic Flow](.././network/traffic_flow.md)

#### `monitor_center` & `monitor_outpost`
These are the key roles in my monitoring setup which is discussed in depth in this document.
> [Monitoring Setup](./monitoring.md)

#### `edgeshark`

This is an on-call service meaning it will not be in use at all time but only when I need easier network traffic debugging for container related network traffic.

Responsibilities
- provide a web interface for choosing an interface to wireshark sniff
- provide a wireshark sniff for all interface, host and each container interface

### End Service Roles
> roles that are: added only to particular servers for providing an end service

These roles are all very simple deployments of end services that possibly may require multiple containers but not always.

To learn about what went in my end service choices you can read this blog post I made.
> https://blog.wiresndreams.dev/my-general-and-homelab-tools-plan

## Current IaC Achievements
https://sdh.global/media/docs/SDH_The_Complete_Guide_to_Infrastructure_as_Code_Architecture.pdf

### For automation it
- **Makes deployment easy and fast**, both initial and re-deployment in the case of disaster recovery.
- **Makes configuration become documentation** as the configuration specifications provide what amounts to version controlled documentation of what configuration has been done and how.
- **Lowers maintenance work** as project-wide configuration is in one place, the GitHub repository, and that configuration is broken up into smaller components that can be investigated individually. Additionally, it is all version controlled so rollbacks are possible and changes are easily tracked plus investigated.
- **Makes configuration reusable and easier to expand on** as configuration components are coded just once reducing bugs and are easily called up for multiple times for different Homelab areas.

### For performance it
- **Makes adjusting to available resources easier** as I can more easily move services around based on available hardware resources and environments.

### For security
- **Reduces misconfiguration vulnerabilities** from manual configuration and configuration duplication.
- **Makes configuration audits easier** so problems and areas of potential improvement can be more easily addressed.
- **Provides an expected state and deterministic deployment** so servers can be can be checked for if anything has gone wrong and refreshed easily if suspect.