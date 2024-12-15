#!/usr/bin/env bash

wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2

# Set the VM ID to operate on
VMID=9001
# Choose a name for the VM
TEMPLATE_NAME=Debian12CloudInit
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
    echo "File already exists."
    echo "Finished"
    exit 1
fi

mkdir -p /var/lib/vz/snippets

tee "/var/lib/vz/snippets/${CLOUD_CONF}" <<EOF
#cloud-config
ssh_pwauth: false
ssh_deletekeys: false

users:
- name: ansible
  gecos: Ansible User
  groups: users,admin,wheel
  sudo: ALL=(ALL) NOPASSWD:ALL
  shell: /bin/bash
  lock_passwd: true
  ssh_authorized_keys:
    - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDJdBIfJQdzYB1g2KCK40AutqNIIKeZqd43J7wQLSTGKjm32cCegDfYiKiRJouHeygwFWgaj2Gdby9C714Uhf1aAn4yFUvzGvSz7j7muxs9987DxIvqJ1Z7XD2KPaK9iUgroj+E0NbyBtHyA7MzICd80HJbiVxOvagvIUxOyP2mN/aU2ICH3K0TThoc01g8zMggA1CjRUkzJZDqotRc66D+ZVtndYD5ql8FuDhTGOeF9SsK9ybQg5alW6EDosHblFh82iKFAvmHPeYD8qzfTDKkddl+hrIHEI9YVwZJpzBOF6nyWWiH4kD54IF8bhbvewIHHgFwask/6k1+/nxF7DX/8tV7T8PPDP3Wd3CYlZlyoOAwkeVlkImbf3+qU7oLCa4M98M/N3m9djiIWIEGvpdB3A0hcjTjOGMlAGkdms19qWeoKm3L1PSf85juE7jkMAT6uuBC9KzcHi4u/L7SK/P2+R3jn4N+QWIev+UFgHudgEA8Pcq0j7KWvjtHHJyylZc= nero@stardom"

runcmd:
  - chmod 700 /home/ansible/.ssh
  - chmod 600 .ssh/authorized_keys

package_update: true
package_upgrade: true
EOF
