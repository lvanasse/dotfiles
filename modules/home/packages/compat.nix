{ ... }:
{
  flake.modules.homeManager.packagesCompat =
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
