{ config, ... }:
{
  flake.modules.nixos.programs =
    { ... }:
    {
      imports = [
        config.flake.modules.nixos.programsSystem
        config.flake.modules.nixos.programsGaming
        config.flake.modules.nixos.programsVirtualization
      ];
    };
}
