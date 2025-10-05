# Desktop environment modules
{ config, pkgs, ... }:
{
  imports = [
    ./fonts.nix
    ./audio.nix
    ./plasma.nix
  ];
}
