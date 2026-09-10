{ ... }:
{
  flake.modules.nixos."feature.steam" =
    { ... }:
    {
      programs.steam = {
        enable = true;
        gamescopeSession.enable = true;
        remotePlay.openFirewall = true;
      };

      programs.gamemode.enable = true;
    };
}
