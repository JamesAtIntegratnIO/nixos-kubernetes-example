{
  pkgs,
  config,
  ...
}: {
  imports = [../default.nix];
  networking = {
    hostName = "node2";
    interfaces.eth0.ipv4.addresses = [
      {
        address = "10.0.3.102";
        prefixLength = 9;
      }
    ];
  };
}
