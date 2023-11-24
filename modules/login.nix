# Allow yourself to SSH to the machines using your public key
# Shamelessly stolen from https://github.com/justinas/nixos-ha-kubernetes/commit/70673cd3d2104b85c0a900d3c62d04af524b904d#diff-8803305d556a87a333ed1b87bd703e2440bf41a47a1358dbc5e04eb3f799054d
let
  # read the first file that exists
  # filenames: list of paths
  readFirst = filenames:
    builtins.readFile
    (builtins.head (builtins.filter builtins.pathExists filenames));

  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMUgouRGqNgbaBlyGh2hx+rZB72ev7DtcStA3vD9ziZ";
in
  {config, ...}: {
    networking.firewall.allowedTCPPorts = config.services.openssh.ports;
    services.openssh.enable = true;
    users.users.root.openssh.authorizedKeys.keys = [sshKey];
  }
