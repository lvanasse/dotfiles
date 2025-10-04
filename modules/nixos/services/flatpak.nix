# Flatpak application management
{ config, pkgs, ... }:
{
  services.flatpak = {
    enable = true;
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };
}