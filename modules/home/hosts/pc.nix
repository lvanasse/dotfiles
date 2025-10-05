{ config, ... }:
{
  programs.plasma = {
    enable = true;
    workspace = {
      # Set desktop wallpaper for PC only (install into home and reference absolute path)
      wallpaper = "${config.home.homeDirectory}/.local/share/wallpapers/13-Ventura-Dark.jpg";
      # Set color scheme to MacVentura-Dark
      colorScheme = "MacVentura-Dark";
      # Global Look-and-Feel removed to avoid overriding explicit pieces

      # Requested theming via plasma-manager
      iconTheme = "Tela-dark";
      cursor = {
        theme = "WhiteSur-cursors";
      };
      splashScreen.theme = "MacVentura-dark";
    };

    # KWin options
    kwin = {
      # Disable edge barrier so the pointer can cross screens freely
      edgeBarrier = 0;
      cornerBarrier = false;
    };
  };

  # Ensure the wallpaper file is present in the user's home
  home.file.".local/share/wallpapers/13-Ventura-Dark.jpg".source =
    ../../../wallpapers/13-Ventura-Dark.jpg;

  # Ensure public SSH keys are present for reproducibility
  home.file.".ssh/id_ed25519_personal.pub".source = "${inputs.secrets}/keys/id_ed25519_personal.pub";
  home.file.".ssh/id_ed25519_work.pub".source = "${inputs.secrets}/keys/id_ed25519_work.pub";

  # Hyprland (Home Manager, PC-only). Scoped to hyprland-session via systemd integration
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true; # ensures Hyprland user services don't run under KDE
    # Minimal config to silence HM warning; real config can be added later.
    settings = { };
    extraConfig = "# managed by Home Manager";
  };
}
