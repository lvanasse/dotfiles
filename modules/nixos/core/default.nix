{ config, ... }:
{
  flake.modules.nixos.core =
    { ... }:
    {
      imports = [
        config.flake.modules.nixos."core.nix"
        config.flake.modules.nixos."core.locale"
        config.flake.modules.nixos."core.networking"
        config.flake.modules.nixos."core.users"
      ];
    };
}
