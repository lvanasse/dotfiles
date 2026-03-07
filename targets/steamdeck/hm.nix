{ flakeModules, ... }:
{
  imports = [
    flakeModules.homeManager.core
    flakeModules.homeManager."terminal.fish"
    flakeModules.homeManager."terminal.starship"
    flakeModules.homeManager."targetConfig.steamdeck"
  ];
}
