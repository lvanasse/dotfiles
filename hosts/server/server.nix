{ inputs, username, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko.nix
    # hardware-configuration.nix will be generated during install
  ];

  # Server-specific settings
  users.users.${username}.initialPassword = "changeme";

  # Server identity/time services
  networking.timeServers = [
    "time1.google.com"
    "time2.google.com"
    "time3.google.com"
    "time4.google.com"
  ];
  networking.nameservers = [ "1.1.1.1" ];
}
