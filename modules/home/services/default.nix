{ config, ... }:
{
  flake.modules.homeManager.services =
    { ... }:
    {
      imports = [
        config.flake.modules.homeManager."services.gnome-keyring"
      ];
    };
}
