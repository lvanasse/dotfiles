# Home Manager packages
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./development.nix
    ./desktop.nix
    ./gaming.nix
    ./creative.nix
  ];
}