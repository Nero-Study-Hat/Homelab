#!/usr/bin/env bash

project_dir="~/Workspace/Tech/IT/Homelab"

cd "${project_dir}/terraform"
terraform plan
terra-apply # manually must confirm here

cd "${project_dir}/ansible/plays"

ansible-playbook -i ../inventory.yaml swap_setup
ansible-playbook -i ../inventory.yaml docker-install.yaml

ansible-playbook -i ../inventory.yaml traefik-setup.yaml

sudo tailscale set --accept-routes=true

ansible-playbook -i ../inventory.yaml nextcloud-setup.yaml

# for cloudinit-tailscale machine dns
# https://serverfault.com/a/1165173

docker stop $(docker ps -a -q)
docker system prune -a
docker volume prune -a
sudo rm -rf docker/

# remove any stopped containers and all unused images
# docker stop 
# docker system prune -a
# docker volume prune -a

# export docker_dir="/home/ansible/docker"
# sudo rm -rf "${docker_dir}/" "${docker_dir}/"

# for using/keeping existing named volumes
# docker compose dosetting up zsh autocomplete on nixos