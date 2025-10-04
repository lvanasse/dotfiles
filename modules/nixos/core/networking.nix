# Basic networking configuration
{ config, pkgs, ... }:
{
  # Enable NetworkManager
  networking.networkmanager.enable = true;

  # Security
  security.polkit.enable = true;
}