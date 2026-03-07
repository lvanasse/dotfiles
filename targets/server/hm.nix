{ flakeModules, ... }:
{
  imports = [
    flakeModules.homeManager.core
    flakeModules.homeManager.terminal
    flakeModules.homeManager."targetConfig.server"
  ];
}
