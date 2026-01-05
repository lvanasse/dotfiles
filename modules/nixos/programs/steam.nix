{ ... }:
{
  flake.modules.nixos."feature.steam" =
    { ... }:
    {
      programs.steam = {
        enable = true;
        gamescopeSession.enable = true;
      };

      programs.gamemode.enable = true;
    };
}
