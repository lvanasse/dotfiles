# Core system modules
{ config, pkgs, ... }:
{
  imports = [
    ./nix.nix
    ./locale.nix
    ./networking.nix
    ./users.nix
  ];
}
