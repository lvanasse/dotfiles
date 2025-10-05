# Hyprland desktop (system-level)
{ config, pkgs, lib, ... }:
{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Keep portals minimal and generic. Plasma will use KDE’s portal,
  # Hyprland will prefer its own when running, GTK is a safe fallback.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };
}

