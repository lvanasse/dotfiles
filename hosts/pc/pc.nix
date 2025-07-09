{ inputs, hostname, username, overlays, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix
  ];

  networking.hostName = hostname;
  users.users.${username}.extraGroups = [ "wheel" ];
}
