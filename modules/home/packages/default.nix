{ config, ... }:
{
  flake.modules.homeManager.packages =
    { ... }:
    {
      imports = [
        config.flake.modules.homeManager."packages.development"
        config.flake.modules.homeManager."packages.desktop"
        config.flake.modules.homeManager."packages.cad"
        config.flake.modules.homeManager."packages.compat"
        config.flake.modules.homeManager."packages.containers"
        config.flake.modules.homeManager."packages.serial"
        config.flake.modules.homeManager."packages.gaming"
      ];
    };
}
