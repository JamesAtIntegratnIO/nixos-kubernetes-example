{
  pkgs,
  config,
  ...
}: {
  imports = [../default.nix];
  networking = {
    hostName = "node1";
    interfaces.eth0.ipv4.addresses = [
      {
        address = "10.0.3.101";
        prefixLength = 9;
      }
    ];
  };
}
