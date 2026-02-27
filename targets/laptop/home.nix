{ flakeModules, ... }:
{
  imports = [
    flakeModules.homeManager.core
    flakeModules.homeManager.theme
    flakeModules.homeManager."desktop.common"
    flakeModules.homeManager."desktop.sway"
    flakeModules.homeManager."desktop.kde"
    flakeModules.homeManager.programs
    flakeModules.homeManager.services
    flakeModules.homeManager.packages
  ];

  # Laptop-specific Home Manager overrides go here
}
