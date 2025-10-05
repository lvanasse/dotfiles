{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    mangohud
    protonplus
    lutris
    bottles
    heroic
    gamescope
    gamemode
    mpfr
    isl
    xivlauncher
  ];
}