{ ... }:
{
  flake.modules.homeManager."target.config.steamdeck" =
    { pkgs, ... }:
    {
      home.username = "deck";
      home.homeDirectory = "/home/deck";

      home.packages = with pkgs; [
        home-manager
        steamtinkerlaunch
        umu-launcher
        xrdp
        pulseaudio-module-xrdp
      ];
    };
}
