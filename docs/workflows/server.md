#!/usr/bin/env bash

project_dir="~/Workspace/Tech/IT/Homelab"

cd "${project_dir}/terraform"
terraform plan
terra-apply # manually must confirm here

sudo tailscale set --accept-routes=true

cd "${project_dir}/ansible"
ansible-playbook -i inventory/hosts.yaml playbooks/dusk_deploy.yaml


# for cloudinit-tailscale machine dns
# https://serverfault.com/a/1165173

docker stop $(docker ps -a -q)
docker system prune -a
docker volume prune -a
docker network prune -f
rm -r docker/

docker system prune
docker volume prune
docker network prune

# remove any stopped containers and all unused images
# docker stop 
# docker system prune -a
# docker volume prune -a

# export docker_dir="/home/ansible/docker"
# sudo rm -rf "${docker_dir}/" "${docker_dir}/"

# for using/keeping existing named volumes
# docker compose dosetting up zsh autocomplete on nixos