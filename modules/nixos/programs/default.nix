# System programs modules
{ config, pkgs, ... }:
{
  imports = [
    ./system.nix
    ./gaming.nix
  ];
}
