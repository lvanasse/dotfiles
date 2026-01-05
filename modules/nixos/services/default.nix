{ config, ... }:
{
  flake.modules.nixos.services =
    { ... }:
    {
      imports = [
        config.flake.modules.nixos.servicesVirtualization
        config.flake.modules.nixos.servicesFlatpak
        config.flake.modules.nixos.servicesPrinting
        config.flake.modules.nixos.servicesPower
        config.flake.modules.nixos.servicesSecrets
        config.flake.modules.nixos.servicesKeyring
        config.flake.modules.nixos.servicesSsh
        config.flake.modules.nixos.servicesSshKeys
        config.flake.modules.nixos.servicesTailscale
      ];
    };
}
