{ config, ... }:
{
  flake.modules.homeManager."profile.workstation" =
    { ... }:
    {
      imports = [
        config.flake.modules.homeManager.core
        config.flake.modules.homeManager.theme
        config.flake.modules.homeManager."desktop.common"
        config.flake.modules.homeManager.programs
        config.flake.modules.homeManager.services
        config.flake.modules.homeManager.packages
      ];
    };
}
