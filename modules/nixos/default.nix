# Main NixOS configuration modules
{ config, pkgs, ... }:
{
  imports = [
    ./core
    ./desktop
    ./services
    ./programs
  ];
}
