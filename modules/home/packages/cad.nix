{ ... }:
{
  flake.modules.homeManager."packages.cad" =
    { pkgs, ... }:
    {
      # CAD and design packages
      home.packages = with pkgs; [
        # CAD and design
        kicad-small
        freecad
      ];
    };
}
