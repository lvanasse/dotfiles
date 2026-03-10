{ ... }:
{
  flake.modules.homeManager."target.config.steamdeck" =
    { pkgs, ... }:
    {
      home.username = "deck";
      home.homeDirectory = "/home/deck";

      home.packages = with pkgs; [
        xrdp
        pulseaudio-module-xrdp
      ];
    };
}
