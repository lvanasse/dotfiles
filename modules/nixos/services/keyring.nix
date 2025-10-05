# Keyring and credential management
{ config, pkgs, ... }:
{
  services.gnome.gnome-keyring.enable = true;
}
