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
    source_file = "./secrets/secrets.yaml"
}

provider "proxmox" {
    pm_tls_insecure = true
    pm_api_url = data.sops_file.sops-secret.data["pm_url"]
    pm_user = data.sops_file.sops-secret.data["pm_user"]
    pm_password = data.sops_file.sops-secret.data["pm_password"]
}

# docs for options here
# https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/resources/vm_qemu.md

resource "proxmox_vm_qemu" "provision-test" {
    name = "vm-test"
    desc = "A test VM."
    target_node = "pve"
    # enable qemu guest agent
    agent = 1
    # UEFI bios
    bios = "ovmf"
    boot = "order=scsi0;ide2;net0;"
    cores = 2
    memory = 2048
    balloon = 2048
    # start immidiately with proxmox node
    onboot = false
    # startup = "order=2"
    os_type = "Linux 6.x - 2.6 Kernel"
    scsihw = "virtio-scsi-single"
    vcpus                     = 0
    automatic_reboot = false

    disks {
        scsi {
            scsi0 {
                cdrom {
                    iso = "local:iso/debian-12.8.0-amd64-netinst.iso"
                }
            }
            scsi1 {
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
                    size               = "32G"
                    storage            = "data-hdd"
                }
            }
        }
    }

    efidisk {
        storage = "local-lvm"
    }

    network {
        id        = 0
        bridge    = "vmbr0"
        firewall  = false
        model     = "virtio"
        queues    = 2 # num of cores
    }

    # this allows the apply to complete without the qemu-guest-agent pckg running and installed in the vm
    define_connection_info =  false
}