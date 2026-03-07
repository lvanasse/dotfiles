{ ... }:
{
  flake.modules.homeManager."packages.compat" =
    { pkgs, ... }:
    {
      # Windows compatibility layer
      home.packages = with pkgs; [
        wine
        winetricks
        mono
      ];
    };
}
