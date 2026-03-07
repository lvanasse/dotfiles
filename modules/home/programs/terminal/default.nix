{ config, ... }:
{
  flake.modules.homeManager.terminal =
    { ... }:
    {
      imports = [
        config.flake.modules.homeManager."terminal.bash"
        config.flake.modules.homeManager."terminal.fish"
        config.flake.modules.homeManager."terminal.starship"
        config.flake.modules.homeManager."terminal.wezterm"
        config.flake.modules.homeManager."terminal.foot"
      ];
    };

  flake.modules.homeManager.terminalBash = config.flake.modules.homeManager."terminal.bash";
  flake.modules.homeManager.terminalFish = config.flake.modules.homeManager."terminal.fish";
  flake.modules.homeManager.terminalStarship = config.flake.modules.homeManager."terminal.starship";
  flake.modules.homeManager.terminalWezterm = config.flake.modules.homeManager."terminal.wezterm";
  flake.modules.homeManager.terminalFoot = config.flake.modules.homeManager."terminal.foot";
}
