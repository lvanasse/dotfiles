{ config, ... }:
{
  flake.modules.homeManager."desktop.common" =
    { ... }:
    {
      imports = [
        config.flake.modules.homeManager."desktop.gtk"
        config.flake.modules.homeManager."desktop.xdg"
      ];
    };
}
