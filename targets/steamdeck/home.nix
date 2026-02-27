{ flakeModules, pkgs, ... }:
{
  imports = [
    flakeModules.homeManager.core
    flakeModules.homeManager.terminalFish
    flakeModules.homeManager.terminalStarship
  ];

  home.username = "deck";
  home.homeDirectory = "/home/deck";

  home.packages = with pkgs; [
    xrdp
    pulseaudio-module-xrdp
  ];
}
