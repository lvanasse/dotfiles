# Main NixOS configuration modules
{ config, pkgs, ... }:
{
  imports = [
    ./core
    ./desktop
    ./services
    ./programs
    ../common/users.nix  # Keep the existing users module
  ];
}