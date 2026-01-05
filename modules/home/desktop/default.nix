{ config, ... }:
{
  flake.modules.homeManager."desktop.common" =
    { ... }:
    {
      imports = [
        config.flake.modules.homeManager.desktopGtk
        config.flake.modules.homeManager.desktopXdg
      ];
    };
}
