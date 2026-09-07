{ ... }:
{
  flake.modules.nixos."programs.gaming" =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        mangohud
        protonplus
        lutris
        bottles
        heroic
        gamescope
        gamemode
        umu-launcher
        mpfr
        isl
        xivlauncher
      ];
    };
}
