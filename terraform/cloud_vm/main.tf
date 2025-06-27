locals {
    os_disk_size = "30G"
    # data_disk_size = "2T"
    data_disk_size = "500G"
    netconfig0 = "ip=10.20.1.6/24,gw=10.20.1.1"
    mac_address = "7a:7b:e2:51:43:90"
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
resource "proxmox_vm_qemu" "debian12-cloud" {

    name = "debian12-cloud"
    desc = "Cloud Server"
    target_node = "pve"

    # Activate QEMU agent for this VM
    agent = 1

    bios = "ovmf"
    boot = "order=scsi0;"
    automatic_reboot = false

    cores = 2
    memory = 2048
    balloon = 2048
    scsihw = "virtio-scsi-single"

    # start immidiately with proxmox node
    onboot = true
    startup = "order=2"

    # Cloud-Init Pre-Reqs configuration
    os_type = "cloud-init"
    clone = "Debian12-Tailscale"

    # Cloud-Init configuration
    # user is required for running custom cloud init config file
    cicustom = "vendor=local:snippets/ansible_user_setup.yml"
    ciuser     = data.sops_file.sops-secret.data["ci_user"]
    cipassword = data.sops_file.sops-secret.data["ci_password"]
    ipconfig0  = local.netconfig0
    nameserver = "1.1.1.1 8.8.8.8"
    sshkeys    = data.sops_file.sops-secret.data["auth_sshkey"]


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

    network {
        id = 0
        macaddr = local.mac_address
        model = "virtio"
        bridge = "vmbr101"
        queues = 2 # num of cores
    }
}