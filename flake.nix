{
	description = "My Homelab IaC dev environment.";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";
	};

	outputs = {
		self,
		nixpkgs,
		flake-utils,
		...
	}:
	flake-utils.lib.eachDefaultSystem (system:
		let
			# pkgs = nixpkgs.legacyPackages.${system};
			pkgs = import nixpkgs {
				inherit system;
				pkgs = nixpkgs.legacyPackages.${system};
				config.allowUnfree = true;
			};
		in rec {
			devShell = pkgs.mkShell {
				packages = with pkgs; [
					terraform
					go
					ansible
					ansible-lint
					sops
					age
                	libguestfs
                	guestfs-tools
					nmap
					openssl
				];

				shellHook = ''
					echo "Starting new shell";
					export ANSIBLE_CONFIG="ansible/ansible.cfg"
				'';
			};
		}
	);
}