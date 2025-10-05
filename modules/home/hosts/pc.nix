{ config, pkgs, inputs, ... }:
{
  programs.plasma = {
    enable = true;
    # Set desktop wallpaper for PC only (install into home and reference absolute path)
    workspace.wallpaper = "${config.home.homeDirectory}/.local/share/wallpapers/13-Ventura-Dark.jpg";
    # Set color scheme to MacVentura-Dark
    workspace.colorScheme = "MacVentura-Dark";
    # Optional: use the matching Look-and-Feel package if available
    workspace.lookAndFeel = "com.github.vinceliuice.MacVentura-Dark";
  };

  # Ensure the wallpaper file is present in the user's home
  home.file.".local/share/wallpapers/13-Ventura-Dark.jpg".source = ../../../wallpapers/13-Ventura-Dark.jpg;

  # Hyprland (Home Manager, PC-only). Scoped to hyprland-session via systemd integration
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true; # ensures Hyprland user services don't run under KDE
    # Keep config minimal for now; we’ll extend later.
    settings = { };
  };
}
