{ config, ... }:
{
  flake.modules.homeManager.services =
    { ... }:
    {
      imports = [
        config.flake.modules.homeManager."services.gnome-keyring"
        config.flake.modules.homeManager."services.ntfy-subscriber"
      ];
    };
}
