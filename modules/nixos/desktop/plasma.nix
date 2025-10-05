# KDE Plasma desktop environment
{ pkgs, ... }:
{
  # Display manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Desktop environment
  services.desktopManager.plasma6.enable = true;

  # Additional desktop packages
  environment.systemPackages = with pkgs; [
    kdePackages.sddm-kcm
  ];
}
