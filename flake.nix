{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixos-generators = {
      url = github:nix-community/nixos-generators;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    ...
  }: {
    devShells.x86_64-linux = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      make-proxmox-image = pkgs.writeShellScriptBin "make-proxmox-image" ''
        #!/usr/bin/env bash
        set -euo pipefail
        nix build .#nixosConfigurations.$1.config.system.build.VMA
      '';
      make-cluster-images = pkgs.writeShellScriptBin "make-cluster-images" ''
        #!/usr/bin/env bash
        set -euo pipefail
        nix flake show --json | jq  '.nixosConfigurations|keys[]'| xargs -I {} -P 0 nix build .#nixosConfigurations.{}.config.system.build.VMA -o /tmp/{}
      '';
      deploy-images = pkgs.writeShellScriptBin "deploy-images" ''
        #!/usr/bin/env bash
        set -euo pipefail
        read -p 'Enter the IP of the proxmox host: ' proxmox_host
        read -p 'Enter first node ID#: ' node_id
        nodes=$(nix flake show --json | jq  '.nixosConfigurations|keys[]')
        echo $nodes | xargs -n 1 | awk -v proxmox_host=$proxmox_host '{print " /tmp/"$1"/vzdump-qemu-"$1".vma.zst root@"proxmox_host":/var/lib/vz/dump/"}' | xargs -L 1 scp
        echo $nodes | xargs -n 1 | awk -v node_id="$node_id" -v proxmox_host="$proxmox_host" '{print "root@"proxmox_host" qmrestore /var/lib/vz/dump/vzdump-qemu-"$1".vma.zst " node_id+i++}' | xargs -L 1 ssh
      '';
      yolo = pkgs.writeShellScriptBin "yolo" ''
        #!/usr/bin/env bash
        set -euo pipefail

        read -p 'Enter the IP of the proxmox host: ' proxmox_host
        read -p 'Enter first node ID#: ' node_id
        nodes=$(nix flake show --json | jq  '.nixosConfigurations|keys[]')

        nix flake show --json | jq  '.nixosConfigurations|keys[]'| xargs -I {} -P 0 nix build .#nixosConfigurations.{}.config.system.build.VMA -o /tmp/{}
        echo $nodes | xargs -n 1 | awk -v proxmox_host=$proxmox_host '{print " /tmp/"$1"/vzdump-qemu-"$1".vma.zst root@"proxmox_host":/var/lib/vz/dump/"}' | xargs -L 1 scp
        echo $nodes | xargs -n 1 | awk -v node_id="$node_id" -v proxmox_host="$proxmox_host" '{print "root@"proxmox_host" qmrestore /var/lib/vz/dump/vzdump-qemu-"$1".vma.zst " node_id+i++}' | xargs -L 1 ssh
      '';
    in {
      myshell = pkgs.mkShell {
        name = "kube-devshell";
        nativeBuildInputs = [
          pkgs.kubectl
          pkgs.jq
          make-proxmox-image
          make-cluster-images
          deploy-images
          yolo
        ];
      };
    };
    nixosConfigurations = let
      proxmoxImageSettings = {
        name,
        virtio0 ? "local-zfs",
        cores ? 4,
        memory ? 4096,
        additionalSpace ? "2000M",
      }: {
        qemuConf = {
          name = name;
          virtio0 = virtio0;
          cores = cores;
          memory = memory;
          # diskSize = "2000M";
          # additionalSpace = additionalSpace;
        };
      };
    in {
      # nix build .#nixosConfigurations.node1.config.system.build.VMA
      node1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./systems/node1
          ./modules/k8s/server.nix
          ./modules/login.nix
          ({
            modulesPath,
            pkgs,
            config,
            ...
          }: {
            imports = [
              "${modulesPath}/virtualisation/proxmox-image.nix"
            ];
            proxmox = proxmoxImageSettings {
              name = config.networking.hostName;
              # diskSize = "20G";
            };
          })
        ];
      };
      # nix build .#nixosConfigurations.node2.config.system.build.VMA
      node2 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./systems/node2
          ./modules/k8s/worker.nix
          ./modules/login.nix
          ({
            modulesPath,
            pkgs,
            config,
            ...
          }: {
            imports = [
              "${modulesPath}/virtualisation/proxmox-image.nix"
            ];
            proxmox = proxmoxImageSettings {
              name = config.networking.hostName;
              # diskSize = "20G";
            };
          })
        ];
      };
      # nix build .#nixosConfigurations.node3.config.system.build.VMA
      node3 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./systems/node3
          ./modules/k8s/worker.nix
          ./modules/login.nix
          ({
            modulesPath,
            pkgs,
            config,
            ...
          }: {
            imports = [
              "${modulesPath}/virtualisation/proxmox-image.nix"
            ];
            proxmox = proxmoxImageSettings {
              name = config.networking.hostName;
              # diskSize = "20G";
            };
          })
        ];
      };
    };
  };
}
