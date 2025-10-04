# Main Home Manager configuration modules
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./core.nix
    ./programs
    ./packages
  ];
}