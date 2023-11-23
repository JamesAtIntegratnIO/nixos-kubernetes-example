{
  pkgs,
  config,
  ...
}: {
  imports = [../default.nix];
  networking = {
    hostName = "node3";
    interfaces.eth0.ipv4.addresses = [
      {
        address = "10.0.3.103";
        prefixLength = 9;
      }
    ];
  };
}
