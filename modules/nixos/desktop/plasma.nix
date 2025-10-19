# KDE Plasma desktop environment
{ pkgs, lib, ... }:
{
  # Display manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    # Revert to default SDDM theme
  };

  # Desktop environment
  services.desktopManager.plasma6.enable = true;

  # Additional desktop packages (none specific)

  # Enable XDG desktop portals suitable for Plasma sessions
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
      xdg-desktop-portal-gtk
    ];
    # Prefer KDE portal when running in Plasma sessions, fall back to GTK
    config.kde.default = lib.mkForce "kde;gtk";
  };
}
