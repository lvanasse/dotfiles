{ ... }:
{
  flake.modules.homeManager."host.steamdeck" =
    { pkgs, ... }:
    {
      home.username = "deck";
      home.homeDirectory = "/home/deck";

      home.packages = with pkgs; [
        xrdp
        xorgxrdp
      ];
    };
}
