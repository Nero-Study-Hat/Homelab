#!/usr/bin/env bash

### Run Process:
### pre-req: run on the proxmox node with root
### cmd: ./script.sh "9002"

tailscale_auth_key=""

wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2

# Set the VM ID to operate on
VMID="$1"
# Choose a name for the VM
TEMPLATE_NAME="Debian12-Tailscale"
# Choose the disk image to import
DISKIMAGE=debian-12-genericcloud-amd64.qcow2
# Select Host disk
HOST_DISK=local-lvm

virt-customize -a "$DISKIMAGE" --install qemu-guest-agent,curl,wget,nano,rsync,htop
virt-customize -a "$DISKIMAGE" --run-command "sed -i 's|send host-name = gethostname();|send dhcp-client-identifier = hardware;|' /etc/dhcp/dhclient.conf"
virt-customize -a "$DISKIMAGE" --run-command "echo -n > /etc/machine-id"

echo "Finished Customizing Image"

qm create "$VMID" --name "$TEMPLATE_NAME" --net0 virtio,bridge=vmbr0
qm set "$VMID" --scsi0 "${HOST_DISK}:0,import-from=/root/workin/${DISKIMAGE}"
qm template "$VMID"

echo "Template Created"

# Move in a cloud_init config file for later
# provisioning if it does not already exist.
CLOUD_CONF="ansible_user_setup.yml"

if [ -f "/var/lib/vz/snippets/${CLOUD_CONF}" ]; then
    rm "/var/lib/vz/snippets/${CLOUD_CONF}"
fi

mkdir -p /var/lib/vz/snippets

tee "/var/lib/vz/snippets/${CLOUD_CONF}" > /dev/null <<EOF
#cloud-config
ssh_pwauth: false

users:
- name: ansible
  gecos: Ansible User
  groups: users,admin,wheel
  sudo: ALL=(ALL) NOPASSWD:ALL
  shell: /bin/bash
  lock_passwd: true

runcmd:
  - curl -fsSL https://tailscale.com/install.sh | sh
  - tailscale up --ssh --accept-routes --authkey="${tailscale_auth_key}"
  - tailscale set --ssh
  - curl -fsSL https://get.docker.com | sh

package_update: true
package_upgrade: true
EOF
