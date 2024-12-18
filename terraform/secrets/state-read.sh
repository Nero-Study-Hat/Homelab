#!/usr/bin/env bash

sshkey="/etc/ssh/ssh_host_ed25519_key"
plain_file="$HOME/terraform.tfstate"
encrypted_file="terraform.tfstate.age"

age -d -i "$sshkey" "$encrypted_file" > "$plain_file"
code --wait "$plain_file"
shred -zu "$plain_file"