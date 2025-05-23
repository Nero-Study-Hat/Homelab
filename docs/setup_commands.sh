#!/usr/bin/env bash

project_dir="~/Workspace/Tech/IT/Homelab"

cd "${project_dir}/terraform"
terraform plan
terra-apply # manually must confirm here

cd "${project_dir}/ansible/plays"

ansible-playbook -i ../inventory.yaml swap_setup
ansible-playbook -i ../inventory.yaml docker-install.yaml

ansible-playbook -i ../inventory.yaml traefik-setup.yaml

ansible-playbook -i ../inventory.yaml nextcloud-setup.yaml