> [!important] 
> ***What this document is and is not.***
> 
> This document will explain
> - what my Homelab is responsible for
> - what tools are being used in my Homelab and why each specific tool rather than a competitor or one less technology to manage
> - why my project is organized the way it is with what each part is responsible for

# What my Homelab is responsible for.

There are two core purposes. Hosting all the cool and useful self hosted applications and utilities I find is the first.

Providing the operational infrastructure needed to to do the first is the second.

My three biggest operational needs are
1. **Automation**: Being able to configure it, deploy it, and forget about it. Everything should be able to run for months without intervention while I am busy with other work.
2. **Performance**: Being able to make everything I want to use work well on the limited hardware I have.
3. **Security**: Being able access content from potentially suspicious sources and support users with potentially compromised devices without worrying about a compromise spread to my personal computer or my family and what may come from that.

# Tools
> [!note] 
> Looking for a balance between feature richness and lower development complexity.
> 
> Must be free to use for now.

With that in mind here are the current tools I am using and why

## Virtualization & Provisioning Tools

#### Cloud Init
https://cloudinit.readthedocs.io/en/latest/

I chose to use this tool alongside Terraform and Ansible because it neatly separates the initial deployment system configuration that needs to be done for all servers. This includes ansible user creation and ssh key assignment which needs to dynamic.

This system configuration is out of Terraform's responsibility scope in my project and Ansible is not yet usable at this stage.

Packer is not used currently because not much initial static configuration needed for all VMs like software installation or user management so boot time and initial configuration tasks are already quite fast not to mention there being only 3 VMs for the project currently.

#### Terraform
https://developer.hashicorp.com/terraform/intro

I chose it over alternatives such as Palumi, OpenTofu, etc. because
- The tool fits my project scale well with a low amount of complexity and work to deal with.
- Terraform is heavily used in enterprise production environments making it a resume boost and OpenTofu seems quite simple to convert to if the need is ever there.

> [!note] 
> I hand-rolled local state file encryption myself for this using bash scripting with the `age` encryption tool because it
> - Felt lower in overhead and complexity to me compared to setting up a remote backend for encryption when I wasn't ready yet as Terraform recommends.
> - Still addressed my main concerns of at-rest encryption, commits to the public GitHub repository, and keeping secrets in clear-text only my hardware.
> 
> The scripts
> - https://github.com/Nero-Study-Hat/Homelab/blob/feat/v1-safe-end-services/secrets/state-crypt.sh
> - https://github.com/Nero-Study-Hat/Homelab/blob/feat/v1-safe-end-services/secrets/state-read.sh
> 
> No further comment will be made of my secrets management approach here because there is separate doc for that.
> > [Homelab - Secrets Management](docs/servers/secret_management.md)

#### Proxmox VE
https://yasha.solutions/posts/2025-09-01-introduction-to-proxmox-virtualization/

Proxmox is a FOSS tool that beats XCP-ng and Incus in the networking department with SDN (Software Defined Networking) functionality including VLANs, VXLANs, zones, and various network virtualization options through its built-in SDN stack.

## System Tools

### Operating System(s)

#### Debian 12
https://linuxvox.com/blog/what-is-debian-in-linux/

I am using Debian Linux for my server OS over other Linux distribution such as CentOS and Alpine Linux because Debian is known as the king of stability and for having great support and documentation around.

Considering I only have three servers I was not concerned about saving resource cost compared to the assurance Debian gives me.

#### Alpine Linux
https://alpinelinux.org/about/

If I need to setup a server in a much more resource constrained environment like an AWS EC2 instance on the free tier, then I will use Alpine Linux.

### Configuration & Containerization Tools
> [!important] 
> To learn more about how my system configuration configs are being made go to the Service Generator Tool's docs.
> > https://github.com/Nero-Study-Hat/Homelab-Tools/tree/main/service_config_generator

#### Ansible
https://www.scalecomputing.com/resources/what-is-ansible

I am not using Ansible Tower or Ansible Semaphore because
1. I am currently the only administrator of my relatively small environment. I don't need RBAC (Role Based Access Controls) at the moment.
2. I plan to orchestrate my automation tasks using a separate orchestration service that will handle more than just Ansible.
   refer to this roadmap doc for more details: [Roadmap Overview](docs/roadmap/roadmap_overview.md)
3. I don't need a web UI for replacing the small amount of Ansible cli-tool usage I currently have.

I am not using other system configuration tools because it offers many benefits of a proper system configuration management tool that go beyond scripting without the increased complexity and knowledge requirements of other tools in the same space.

Ansible is the best option here as it avoids complexity overhead at my project scale while addressing issues that lie in scripting alone.

#### Docker Compose
https://docs.docker.com/compose/

I chose Docker Compose over Podman and K3S because
1. Learning and using it boosts my chances of getting a job.
2. It offered a very simple introduction to containerization.

I will continue to use it until I feel I have learned Docker at a deep level and wave 1 of my [Roadmap](docs/roadmap/roadmap_overview.md) is complete.

## Core Network Tools
> [!important]
> To learn more about what I am using in my networking setup and how I have approached it with why go to these docs.
> > [Network Setup](docs/network/main.md)

#### OPNSense
https://www.zenarmor.com/docs/network-security-tutorials/what-is-opnsense

I chose OPNSense over PFSense because OPNSense has a Rest API in development and future work on that front planned while PFSense has no official support for API functionality or released plans for development of such functionality.

This is important to me because
- While I am able to manually configure PFSense and backup that configuration, that takes away a lot of the fine control, ease of auditing, and other features that comes with managing PFSense via IaC using an API.
- While I am currently not leveraging the API features, it is in the roadmap for this project.

#### Tailscale
https://tailscale.com/kb/1151/what-is-tailscale

I chose Tailscale over Headscale because of the available documentation, web UI, full feature set, and my liking of the company.

The notable reasons I chose Tailscale over competitors among Overlay Networks was the
- Open source client with trusted community members vetting and backing the protocols used.
- Client support they offer.
- JSON based access controls that allow GitOps management.
- Feature rich access controls.
- Documentation and teaching material provided.
- Split-DNS feature.
- Sleek web UI experience.

I chose Tailscale over a traditional VPN setup because it keeps the transport security and speed of Wireguard as Tailscale is built using it while adding additional features to match my project needs with the biggest by far being support for connection between various different devices all managed by ACLs to ensure security.

# Project Organization
> [!note] 
> This section will clarify
> - why my project is organized the way it is
> - what each part of the part of the project is responsible for
> - where all the tools I mentioned above are being used

Looking at all the directories and files at the top level of this project's directory hierarchy, there are primary directories and supportive directories.

**Primary directories** are where where code, configuration, etc. that will actively change the Homelab go.
> Includes: `ansible`, `cloud_init`, `secrets`, `terraform`

**Supportive directories and files** is everything else in this repository. These have a focus on making the primary directories contents more usable by providing documentation and a development environment.
> Includes:
> directories:
> 	`.direnv`, `.vscode`, `docs`, `scratchpads`
> files:
> 	`.envrc`, `.gitattributes`, `.gitignore`, `flake.lock`, `flake.nix`, `read.me`

## Primary Directories
> [!important] 
> The primary rule here is separation of different stages of deployment and configuration with the tools choices fitting into this model as described above. This way organizing by tool naturally orders by deployment stage.

Terraform is only responsible for provisioning the VM infrastructure without any system configuration.

Cloud Init will handle initial system configuration on VM deployment and nothing else.

Ansible will only be used on VMs setup with everything already mentioned to handle system configuration tasks.

Docker Compose is managed by Ansible in my setup so it is baked into every Ansible role along with service relevant configuration files.

> [!note] 
> Development on tools is separated into a separate GitHub repository based on the noise it would add to this repository's git history which is focused on defining my infrastructure as code.
> > https://github.com/Nero-Study-Hat/Homelab-Tools

### Content Organization

#### Ansible Directory
All the sub-directories are standard Ansible project directories. Note that work in this area is largely done using the Service Generator Tool I made so it is best to look at the documentation in that project for why the Ansible directory's contents are arranged the way they are.

> https://github.com/Nero-Study-Hat/Homelab-Tools/tree/main/service_config_generator

#### Cloud Init Directory
There is a sub-directory for each connection type a server can be initialized with.

#### Terraform Directory
There is a sub-directory for each VM with `terraform init` done and respective state for each so they can be managed separately. This was important because they don't always go up and down together.

There are no dedicated variable files because my variables requirements don't demand that for now.

> [!note] 
> The `vlan_interfaces` file here is present because it is relevant to the provisioning of network interfaces to the VMs but it is likely to move/change somehow in the future once I automate its handling.

## Supportive Directories & Files

### Docs Organization
These are still in active early development so I'm not sure yet.

### Development Environment
This includes
- The usual git files for version control.
- A VSCode dir for an ansible related setting based on my nix flake
- Nix flake related file for getting all the packages and shell variables I need.
- A .direnv directory and .envrc file for automatically loading my nix flake environment and shell aliases.