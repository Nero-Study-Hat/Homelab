locals {
    cores = 2
    os_disk_size = "50G"
    # data_disk_size = "2T"
    data_disk_size = "500G"
    # cloud-init settings
    cloud_init_name = "Debian12-Tailscale"
    cloud_init_snippet = "vendor=local:snippets/ansible_user_setup.yml"
}

terraform {
  required_providers {
    sops = {
        source = "carlpett/sops"
        version = "1.3.0"
    }
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

data "sops_file" "sops-secret" {
    source_file = "../../secrets/secrets.yaml"
}

provider "proxmox" {
    pm_tls_insecure = true
    pm_api_url = data.sops_file.sops-secret.data["pm_url"]
    pm_user = data.sops_file.sops-secret.data["pm_user"]
    pm_password = data.sops_file.sops-secret.data["pm_password"]
}

# requires cloudinit template already manually setup on proxmox
resource "proxmox_vm_qemu" "debian12-day" {

    name = "debian12-day"
    description = "Day Server"
    target_node = "pve"

    # Activate QEMU agent for this VM
    agent = 1

    bios = "ovmf"
    boot = "order=scsi0;"
    automatic_reboot = false

    cpu {
        cores = local.cores
    }
    memory = 2048
    balloon = 2048
    scsihw = "virtio-scsi-single"

    # start immidiately with proxmox node
    start_at_node_boot = true
    startup_shutdown {
        order = 2
    }

    # Cloud-Init Pre-Reqs configuration
    os_type = "cloud-init"
    clone = local.cloud_init_name

    # Cloud-Init configuration
    # user is required for running custom cloud init config file
    cicustom   = local.cloud_init_snippet
    ciuser     = data.sops_file.sops-secret.data["ci_user"]
    cipassword = data.sops_file.sops-secret.data["ci_password"]
    sshkeys    = data.sops_file.sops-secret.data["auth_sshkey"] #TODO: remove when stable
    
    # network config
    # below IP addresses must be available in the below bridges
    # static dhcp entries are required for the below config
    nameserver = "1.1.1.1 8.8.8.8"
    # vlans
    # Day_Network_Center
    ipconfig0  = "ip=10.20.1.10/29,gw=10.20.1.9"
    # Day_Edgeshark
    ipconfig1  = "ip=10.20.1.26/29,gw=10.20.1.25"
    # Day_Monitor_Outpost
    ipconfig2  = "ip=10.20.1.34/29,gw=10.20.1.33"
    # Day
    # main interface, note: must be last
    ipconfig3  = "ip=10.20.1.6/29,gw=10.20.1.1"



    serial {
        id = 0
    }

    disks {
        scsi {
            scsi0 {
                disk {
                    backup             = true
                    cache              = "none"
                    discard            = true
                    emulatessd         = true
                    iothread           = true
                    mbps_r_burst       = 0.0
                    mbps_r_concurrent  = 0.0
                    mbps_wr_burst      = 0.0
                    mbps_wr_concurrent = 0.0
                    replicate          = true
                    size               = local.os_disk_size
                    storage            = "local-lvm"
                }
            }
            scsi1 {
                disk {
                    backup             = false
                    cache              = "none"
                    discard            = true
                    emulatessd         = true
                    iothread           = true
                    mbps_r_burst       = 0.0
                    mbps_r_concurrent  = 0.0
                    mbps_wr_burst      = 0.0
                    mbps_wr_concurrent = 0.0
                    replicate          = false
                    size               = local.data_disk_size
                    storage            = "data-hdd"
                }
            }
            scsi2 {
                cloudinit {
                    storage = "local-lvm"
                }
            }
        }
    }

    efidisk {
        storage = "local-lvm"
    }

    # for vlan support manually on promox create
    # a linux vlan and linux bridge using that vlan as bridged port
    # then use the final linux bridge here

    # IMPORTANT
    # make sure the bridge number correspond with the vlan tag in OPNSense
    # not just that the interface exists on proxmox 

    ## VLAN INTERFACES ##
    # network center interface
    network {
        id = 0
        macaddr = "be:bb:37:47:6a:84"
        model = "virtio"
        bridge = "vmbr102"
        queues = local.cores # num of cores
    }

    # edgeshark interface
    network {
        id = 1
        macaddr = "ee:76:24:18:a8:05"
        model = "virtio"
        bridge = "vmbr104"
        queues = local.cores # num of cores
    }

    # monitor outpost interface
    network {
        id = 2
        macaddr = "ea:35:e6:41:05:21"
        model = "virtio"
        bridge = "vmbr105"
        queues = local.cores # num of cores
    }

    # main interface NOTE: last id # to be used as default route
    network {
        id = 3
        macaddr = "7a:7b:e2:51:43:90"
        model = "virtio"
        bridge = "vmbr101"
        queues = local.cores # num of cores
    }
}