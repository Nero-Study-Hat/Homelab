# Monitoring

## Setup Overview

### Problem Preface

In my Homelab architecture there are three VMs in different VLANs used. Each has differing risk factors
- day: no risk, highly important
- dusk: low risk
- night: high risk

I don't have the hardware resources to afford more VMs and the resources within those VMs are constrained. As a result the priorities for my monitoring setup are
- Use as little resources as possible.
- Collect as much as I can.
- Collect in a way that the scraped data is easy to reach, view, and use.
- Achieve the above in the most secure way I can find.

### Solution Approach

#### Splitting Outpost and Center

I have made two Ansible roles.
- `monitor_center`: Traefik, Tailscale, Dnsmasq, Grafana, Loki, Mimir, Alloy, Cadvisor
- `monitor_outpost`: Traefik, Tailscale, Dnsmasq, Alloy, Cadvisor

> [!Tip] 
> Standalone Cadvisor alongside Alloy which is scraping its' metrics endpoint is used instead of the Cadvisor exporter shipped with Alloy because the Cadvisor version in Alloy can lag behind leading to slower fixes to breaking changes as has happened to me here.

The monitor center will be deployed only on the Dusk VM. It will contain
1. Services for storing collected data
2. Services for viewing collected data
3. Services for collecting data

The monitor outpost will be deployed on the Day and Night VMs. They will contain
1. Services for collecting data

The purpose of this split is
1. Only host the heavier storage and viewing services once.
2. To enable full collection on all hosts.
3. Only need to go to on place to query the scraped data.
4. Keep the outpost's as attack surface as light as possible and separate the traffic headed out from Night VM from Day VM by an intermediary. Also only enable the outpost to push so it can't pull data from other sources. 

#### Step By Step Process

##### Step 1: Alloy & Cadvisor Scrape
Alloy will collect
- All Docker container logs via Docker socket proxy.
- Prometheus metrics of all Traefik instances on the current host of the given Outpost via Tailscale connection.
- Tailscale Prometheus metrics via Tailscale connection.

Cadvisor will collect
- Host metrics.
- All Docker contain metrics via containerd socket.

##### Step 2: Alloy Forward to Local Traefik
In the Alloy config, the domains used for where to write data to point to the Traefik instance special to the Outpost Docker network which is a sidecar of a Tailscale container with outbound capability.

##### Step 3: Local Traefik Forward to Remote Traefik
The dynamic Traefik rules written in the Alloy container labels, requests for the storage targets will be pointed to the main Traefik instance in the Dusk VM located in the `traefik_tailscale` Docker network established by the `network_center` Ansible role.

With these rules are middleware configurations for adding a tenant header to specify the `{host}-outpost` source and rate limiting to manage the allowed average and burst traffic. 

This will ensure the header is placed by a more hardened and trusted source, Traefik, and that the Alloy instance if compromised can't overwhelm the Dusk VM with Traefik volume.

##### Step 4: Remote Traefik Forward to Remote Data Storage & Remote Data Storage Ingestion
The remote Traefik container will forward data to the intended storage target by domain.

Both my data storage services, Loki and Mimir, are setup to support multi-tenancy based on the incoming request header `X-Scope-OrgID`. This will restrict what incoming requests have as far as permissions go when accessing the storage services' endpoints.

## Monitoring Purpose

My Homelab has three large concerns
- mitigating security risk
- efficient resource usage
- automating manual work

The monitoring setup I have here is a foundation that gives me
- data collection
- data storage
- data viewing

In the future I can expand on those affordances to setup
- automated incident responses and/or alerts to suspicious behaviors and flags in my Homelab
- hardware usage monitoring to see what can be tuned better and how

So my current monitoring stack is mainly a foundation for future potential but as current usage goes it useful for improve log querying and metric insight as well making all of that easy to access with dashboards and everything in the browser.