{ flakeModules, ... }:
{
  imports = [
    flakeModules.nixos.core
    flakeModules.nixos."desktop.common"
    flakeModules.nixos.services
    flakeModules.nixos.programs
    flakeModules.nixos."desktop.sway"
    flakeModules.nixos."desktop.kde"
    flakeModules.nixos."target.config.laptop"
  ];
}
