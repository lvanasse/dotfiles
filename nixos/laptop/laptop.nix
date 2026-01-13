{ config, inputs, ... }:
let
  username = config.flake.lib.username;
in
{
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./hardware.nix
    ./disko.nix
  ];

  users.users.${username}.initialPassword = "linux123";
}
