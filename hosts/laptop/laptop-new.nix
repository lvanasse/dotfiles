{
  inputs,
  hostname,
  username,
  overlays,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
  ];

  # Set hostname
  networking.hostName = hostname;

  # Boot configuration
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    useOSProber = true;
    efiSupport = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Laptop-specific features
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # SSH agent for laptop
  programs.ssh.startAgent = true;
  users.users.ludovic.linger = true;
}