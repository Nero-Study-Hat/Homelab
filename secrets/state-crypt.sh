#!/usr/bin/env bash

sshkey="/etc/ssh/ssh_host_ed25519_key"
plain_file="terraform.tfstate"
encrypted_file="terraform.tfstate.age"

# terraform apply with -> no existing state file or an existing unencrypted state file
function only_encrypt {
    terraform apply
    age -R "${sshkey}.pub" -o "$encrypted_file" "$plain_file"
    shred -zu "$plain_file"
    git add -f "$encrypted_file"
}

# terraform apply with -> an existing encrypted state file
function decrypt_encrypt {
    age -d -i "$sshkey" "$encrypted_file" > "$plain_file"
    shred -zu "$encrypted_file"
    only_encrypt
}

if [ -f "./terraform.tfstate" ] || [[ ! -f "./terraform.tfstate" && ! -f "./terraform.tfstate.enc" ]]; then
    only_encrypt
elif [ -f "./terraform.tfstate.enc" ]; then
    decrypt_encrypt
fi

if [ -f "${plain_file}.backup" ]; then
    shred -zu "${plain_file}.backup"
fi