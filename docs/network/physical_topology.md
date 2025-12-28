## Physical Topology: Full Home

| Physical Topology |
| ----------------- |
| ![Physical Topology](diagrams/physical_topology/physical_topology.png)  |

> [!important] Hardware Device Names Are Excluded Because:
> some reasoning ...


#### Modem Specifications
> [!important] location in house
> first floor networking equipment corner


| **Specification**         | **Details**                                          |
| ------------------------- | ---------------------------------------------------- |
| **DOCSIS Standard**       | DOCSIS 3.0                                           |
| **Channel Bonding**       | 16x4 channel bonding (upgradeable to 24x8)           |
| **Downstream Data Rate**  | Up to **960 Mbps**                                   |
| **Upstream Data Rate**    | Up to **240 Mbps**                                   |
| **VoIP Support**          | Yes, supports two independent phone lines            |
| **Ethernet Ports**        | 1 x RJ-45 Gigabit Ethernet port                      |
| **IPv4 and IPv6 Support** | Yes                                                  |
| **Power Requirements**    | AC power supply, supports options for battery backup |

> [!note] Explanation of Key Specifications
> ##### Channel Bonding
> - **16x4 Channel Bonding (Upgradeable to 24x8)**: This refers to the number of channels used for data transmission. The "16x4" means the modem can use **16 downstream channels** and **4 upstream channels** simultaneously. The configuration can be upgraded to **24 downstream channels** and **8 upstream channels**. More channels allow for increased bandwidth, which directly impacts internet speed and performance.
> ##### Downstream Data Rate
> - **Up to 960 Mbps**: This is the maximum speed at which data can be downloaded from the internet to your device. A higher downstream data rate means faster-loading web pages, quicker file downloads, and better streaming performance.
> ##### Upstream Data Rate
> - **Up to 240 Mbps**: This is the maximum speed at which data can be uploaded from your device to the internet. A higher upstream speed is particularly beneficial for activities like video conferencing, online gaming, and sending large files.
> ##### VoIP Support
> - **Supports Two Independent Phone Lines**: This means that the modem can handle two separate telephone lines using Voice over Internet Protocol (VoIP) technology. It allows users to make and receive calls over the internet using standard telephones without requiring a separate phone line.


#### Proxmox Machine
> [!note] 
> Proxmox is hosting my firewall OPNSense as a VM.
> Only relevant hardware specification details are listed here.

| **Specification** | **Details** |
| ----------------- | ----------- |
| **CPU**           |             |
| **Memory**        |             |
| **Storage**       |             |
| **NIC**           |             |
| **USB**           |             |

##### Ethernet to USB Adapter

| **Specification** | **Details** |
| ----------------- | ----------- |
|                   |             |


##### OPNSense VM Details
> [!note] Listing even though a VM due to important to network

| **Specification** | **Details** |
| ----------------- | ----------- |
|                   |             |


#### Managed Switch

| **Specification** | **Details** |
| ----------------- | ----------- |
|                   |             |


#### Unmanaged Switch x2

| **Specification** | **Details** |
| ----------------- | ----------- |
|                   |             |

Router

| **Specification** | **Details** |
| ----------------- | ----------- |
|                   |             |


#### Walkthrough from Modem to endpoint and back physically.
Details include ports used, speed of those ports, etc.