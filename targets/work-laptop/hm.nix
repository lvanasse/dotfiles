{ flakeModules, ... }:
{
  imports = [
    flakeModules.homeManager.core
    flakeModules.homeManager.theme
    flakeModules.homeManager."desktop.common"
    flakeModules.homeManager."desktop.sway"
    flakeModules.homeManager.programs
    flakeModules.homeManager.services
    flakeModules.homeManager.packages
    flakeModules.homeManager."target.config.hm-only"
    flakeModules.homeManager."target.config.work-laptop"
  ];
}
