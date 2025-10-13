{ config, ... }:
{
  # Hyprland (Home Manager). Scoped to hyprland-session via systemd integration
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true; # ensures Hyprland user services don't run under KDE

    # Sway-like defaults with minimal frills
    settings = {
      # Variables
      "$mod" = "SUPER";

      # Monitors: default to preferred mode on all
      monitor = [ ",preferred,auto,1" ];

      # Input: keep defaults minimal
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
        }; # ignored if no touchpad
      };

      # General look and layout: close to sway defaults (no gaps/blur/animations)
      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 2;
        layout = "dwindle";
      };
      decoration = {
        rounding = 0;
        blur = {
          enabled = false;
        };
      };
      animations = {
        enabled = false;
      };
      dwindle = {
        preserve_split = true;
      };
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      # Startup: set a background (sway-style) using the shared wallpaper
      exec-once = [
        "swaybg -i ${config.home.homeDirectory}/.local/share/wallpapers/13-Ventura-Dark.jpg -m fill"
        "waybar"
        "nm-applet --indicator"
      ];

      # Keybindings (Sway-like)
      bind = [
        # Core actions
        "$mod, Return, exec, alacritty"
        "$mod, D, exec, wofi --show drun"
        "$mod, Q, killactive,"
        "$mod SHIFT, C, reload,"
        "$mod SHIFT, E, exit,"

        # Window state
        "$mod, F, fullscreen, 0"
        "$mod, Space, togglefloating,"

        # Focus movement (hjkl)
        "$mod, H, movefocus, l"
        "$mod, J, movefocus, d"
        "$mod, K, movefocus, u"
        "$mod, L, movefocus, r"

        # Move windows (Shift+hjkl)
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, J, movewindow, d"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, L, movewindow, r"

        # Workspaces 1-9
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"

        # Move active to workspace 1-9
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
      ];

      # Mouse: Sway's floating modifier behavior
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}
