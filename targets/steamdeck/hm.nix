{ flakeModules, ... }:
{
  imports = [
    flakeModules.homeManager.core
    flakeModules.homeManager.terminalFish
    flakeModules.homeManager.terminalStarship
    flakeModules.homeManager."targetConfig.steamdeck"
  ];
}
