{ flakeModules, ... }:
{
  imports = [
    flakeModules.homeManager.core
    flakeModules.homeManager."terminal.fish"
    flakeModules.homeManager."terminal.starship"
    flakeModules.homeManager."target.config.steamdeck"
  ];
}
