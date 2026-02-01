{ config, ... }:
{
  flake.modules.homeManager.terminal =
    { ... }:
    {
      imports = [
        config.flake.modules.homeManager.terminalBash
        config.flake.modules.homeManager.terminalFish
        config.flake.modules.homeManager.terminalStarship
        config.flake.modules.homeManager.terminalWezterm
      ];
    };
}
