{ inputs, username, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./hardware.nix
    ./disko.nix
  ];

  users.users.${username}.initialPassword = "linux123";
}
