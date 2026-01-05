{ config, ... }:
{
  flake.modules.nixos.core =
    { ... }:
    {
      imports = [
        config.flake.modules.nixos.nix
        config.flake.modules.nixos.locale
        config.flake.modules.nixos.networking
        config.flake.modules.nixos.users
      ];
    };
}
