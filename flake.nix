{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
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
    nixosConfigurations = let
      proxmoxImageSettings = {
        name,
        virtio0 ? "local-zfs",
        cores ? 4,
        memory ? 4096,
        additionalSpace ? "20G",
      }: {
        qemuConf = {
          name = name;
          virtio0 = virtio0;
          cores = cores;
          memory = memory;
          additionalSpace = additionalSpace;
        };
      };
    in {
      # nix build .#nixosConfigrations.node1.config.system.build.VMA
      node1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./systems/node1
          ./modules/k8s/server.nix
          ({
            modulesPath,
            pkgs,
            config,
            ...
          }: {
            imports = [
              "${modulesPath}/virtualisation/proxmox-image.nix"
            ];
            proxmox.qemuConf.name = config.networking.hostName;
          })
        ];
      };
      # nix build .#nixosConfigrations.node2.config.system.build.VMA
      node2 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./systems/node2
          ./modules/k8s/worker.nix
          ({
            modulesPath,
            pkgs,
            config,
            ...
          }: {
            imports = [
              "${modulesPath}/virtualisation/proxmox-image.nix"
            ];
            proxmox.qemuConf.name = config.networking.hostName;
          })
        ];
      };
      # nix build .#nixosConfigrations.node3.config.system.build.VMA
      node3 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./systems/node3
          ./modules/k8s/worker.nix
          ({
            modulesPath,
            pkgs,
            config,
            ...
          }: {
            imports = [
              "${modulesPath}/virtualisation/proxmox-image.nix"
            ];
            proxmox.qemuConf.name = config.networking.hostName;
          })
        ];
      };
    };
  };
}
