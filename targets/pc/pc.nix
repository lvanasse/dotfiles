{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./hardware.nix
    ./networking.nix
    ./services.nix
    ./programs.nix
    ./packages.nix
    ./torrenting.nix
  ];
}
