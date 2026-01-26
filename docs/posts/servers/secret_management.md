# Secrets Management
> [!important] 
> Keep in mind this is all very much an interim solution so a lot of what currently stands is expected to change as the project matures.
> 
> What feels like glaring holes are acceptable at the current project stage because they aren't actually glaring holes for where my threat model is at right now. This is considering what is being run and how access is being handled currently.
> 
> To see planned changes look in the
> > [Roadmap Doc](../roadmap/roadmap_overview.md)

## Why I Use SOPS with the Age Backend

1. I already had some experience with SOPS with Age from using it my NixOS personal desktop.
2. It was the simplest and quickest to setup solution to use that I still have decent trust for. Age is a project I like.
3. It addressed all my secret-needs (Ansible, Terraform, Custom Script, Manual Copy) in one location and setup.
4. It keeps my secrets in version control so rollbacks and full past visibility are possible.
5. It fits my current needs (one user, no open environment yet, etc.) at the start of this relatively small personal project.

It also has a benefit I like being it allows for management of secrets in structured formats (e.g., YAML, JSON) by encrypting only values while leaving keys and structure visible which makes double checking secret var names much easier though that of course comes with a trade-off as with everything else in my current setup.

### Why Keep `secrets.yaml` in Public Repository

Even if the secret values are all encrypted it is still best practice to not keep them public on the internet. I have taken this approach so far because I have not opened up a public production environment yet or setup any risky services bringing traffic in so altogether if someone reads my secrets as they currently exist, I would be fine and it wouldn't be a problem. Once this situation changes however I will need to update all my secrets values and not put those on the public web.

## Ansible: SOPS

At the beginning of each of my Ansible playbook you will see this task block.

```yaml
- name: Load Sops Secrets
  community.sops.load_vars:
	file: "{{ playbook_dir }}/../../secrets/secrets.yaml"
	name: sops_secrets
	expressions: ignore  # explicitly do not evaluate expressions
						# on load (this is the default)
```

Overview of what the module does
- Loads SOPS-encrypted YAML/JSON variable files at task runtime, delivering them into a variable scope for use in subsequent tasks. This enables dynamic inclusion of secrets/configs without storing plaintext vars in inventory or roles.
- [Module Ansible Doc](https://docs.ansible.com/ansible/latest/collections/community/sops/load_vars_module.html)

In my case I am loading all SOPS secrets into the global namespace at the beginning of each playbook so they can be accessed by all the following include_role tasks. Then I load select variables into role specific variables to be used at the role level.

The main Ansible specific benefit I have from my approach with SOPS is
> **Dynamic inclusion for secret rotation**:  SOPS used with Ansible facts to load secrets into a role variable, enabling on-the-fly rotation and minimizing blast radius if a secret needs to be updated.

> [!danger] 
> - All secrets in one `secrets.yaml` file with everything in my Homelab accessing this file for all its content even though not all content are needed for everything.

## Terraform: SOPS & Custom with Age

At the beginning of each terraform `.tf` file I have is this block.

```hcl
terraform {
  required_providers {
    sops = {
        source = "carlpett/sops"
        version = "1.3.0"
    }
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

data "sops_file" "sops-secret" {
    source_file = "../../secrets/secrets.yaml"
}
```

These secrets are then accessed by the Proxmox provider block and the Cloud-Init variables as well as the `sshkeys` variable.

SOPS is used here for blanket reasons above.

### Custom State Encryption

When I picked up Terraform I quickly learned that secrets are kept in plaintext in the state file which was a big problem for me as I want to have that file in version control.

I decided not to use a separate state backend because I didn't want to introduce another service and platform to my Homelab. After all part of the reason I went to SOPS was to get away from this complexity and work. Also sharing secrets on infrastructure that isn't mine in plaintext feels uncomfortable even if I know managed hosting solutions like HashiCorp Vault and the like aren't out to get me.

I decided to write some custom scripts and aliases for baking encryption decryption into the Terraform commands step because
1. I was already encrypting these secrets with Age and storing them encrypted in the repository so doing it ago wasn't a stretch.
2. I wanted to learn about file encryption and how I would do this.
3. I was comfortable with Bash scripting and aliases already.

## Cloud Init: SOPS & Manual Work

For the most part Cloud Init secrets are filled in the Terraform files as mentioned above.

Separately when making the VM templates though a Bash script is run on Proxmox which requires me to manually fill the relevant Tailscale Auth Key for the Tailscale Based template. These VM Tailscale keys are stored in the SOPS secrets file for the blanket reason above. Having access in one place and thus always knowing where to go to get and place my secrets is a great help.

## Secrets with Docker & Remote Hosts

This is a combination of Docker Secrets usage and writing secrets to files on the remote host that get mounted into containers as needed.

Docker Secrets are used when possible but many container projects don't support them or simply don't support them conveniently and stably. When used a file is made on the remote host containing the needed secret which Docker picks up and uses.

Secrets are written to the `.env` file on the remote host when the proper secrets approach with Docker is not possible. When used variables are pulled from the `.env` file used interpolated values in the `environment` block of a container block in a Docker Compose.

> [!danger] 
> Currently this approach
> 1. Leaves files on remote host containing secrets even if they are only accessible by root and ansible users.
> 2. Uses environment variables which are not recommended because
> >[!quote]
> >**Environment variables are often available to all processes**, and it can be difficult to track access. They can also be printed in logs when debugging errors without your knowledge. **Using secrets mitigates these risks.** 
> 
> Docker Compose secrets are designed to prevent services within a stack from accessing each others' environment variables. This means not much difference for most of my composes but for some this would be good to have.
> 
> In general for future version of my Homelab I plan to use solutions other than Docker Compose where secrets will be handled better.

## Account Credentials: Bitwarden

All account credentials are currently kept in managed Bitwarden with Yubikey two factor.

This made sense as I already have plenty of important credentials here and I get Yubikey two factor to protect it all. In the future I plan to self host Vaultwarden myself but until then I will be sticking with this.

## Current Risk & A Peek Into The Future

Currently if my singular dev machine is ever compromised then everything is up in smoke as all secrets are accessible, they have my admin Tailscale identity, and have network reach to all infrastructure.

Now to some extent my admin machine will always be important but in the future I want to try to cut this singular importance down a bit.

I also want to introduce additional services for secrets and key management to have a more real world ready solution as opposed to the testing setup I have now.

This means both setting up things like Infiscal, Smallstep, and Vault Warden as well as more strictly managing how secrets are handled with strict introduction to variable namespaces, flushing from variable namespace, separation of variable by scope, and more.