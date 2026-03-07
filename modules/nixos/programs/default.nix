{ config, ... }:
{
  flake.modules.nixos.programs =
    { ... }:
    {
      imports = [
        config.flake.modules.nixos."programs.system"
        config.flake.modules.nixos."programs.gaming"
        config.flake.modules.nixos."programs.virtualization"
      ];
    };
}
