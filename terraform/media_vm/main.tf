locals {
    cores = 2
    os_disk_size = "30G"
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
        version = "1.1.1"
    }
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc6"
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
resource "proxmox_vm_qemu" "debian12-media" {

    name = "debian12-media"
    desc = "Semi-Public Media Server"
    target_node = "pve"

    # Activate QEMU agent for this VM
    agent = 1

    bios = "ovmf"
    boot = "order=scsi0;"
    automatic_reboot = false

    cores = local.cores
    memory = 2048
    balloon = 2048
    scsihw = "virtio-scsi-single"

    # start immidiately with proxmox node
    onboot = true
    startup = "order=2"

    # Cloud-Init Pre-Reqs configuration
    os_type = "cloud-init"
    clone = local.cloud_init_name

    # Cloud-Init configuration
    # user is required for running custom cloud init config file
    cicustom   = local.cloud_init_snippet
    ciuser     = data.sops_file.sops-secret.data["ci_user"]
    cipassword = data.sops_file.sops-secret.data["ci_password"]
    sshkeys    = data.sops_file.sops-secret.data["auth_sshkey"]

    # network config
    # below IP addresses must be available in the below bridges
    # static dhcp entries are required for the below config
    nameserver = "1.1.1.1 8.8.8.8"
    # vlans
    ipconfig0  = "ip=10.20.3.10/29,gw=10.20.3.9"
    ipconfig1  = "ip=10.20.3.18/29,gw=10.20.3.17"
    ipconfig2  = "ip=10.20.3.26/29,gw=10.20.3.25"
    # main interface, note: must be last
    ipconfig3  = "ip=10.20.3.6/29,gw=10.20.3.1"

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

    ## VLAN INTERFACES ##
    # network center interface
    network {
        id = 0
        macaddr = "ca:42:3c:61:6d:8f"
        model = "virtio"
        bridge = "vmbr302"
        queues = local.cores # num of cores
    }

    # monitor outpost interface
    network {
        id = 1
        macaddr = "6a:c9:bd:ad:39:16"
        model = "virtio"
        bridge = "vmbr303"
        queues = local.cores # num of cores
    }

    # edgeshark interface
    # TODO: edgeshark setup
    # opnsense work and .tf work here are done
    # needs tailscale key, set address, and grants to be available to run
    network {
        id = 2
        macaddr = "3e:1c:43:2e:50:5a"
        model = "virtio"
        bridge = "vmbr304"
        queues = local.cores # num of cores
    }

    # main interface NOTE: last id # to be used as default route
    network {
        id = 3
        macaddr = "e6:20:5f:93:ec:ec"
        model = "virtio"
        bridge = "vmbr301"
        queues = local.cores # num of cores
    }
}