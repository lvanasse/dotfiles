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
        kb_variant = "intl"; # us-intl with dead keys
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
        # Gruvbox Dark Hard borders (no focus highlight)
        "col.active_border" = "rgb(3c3836)"; # match inactive to avoid highlight
        "col.inactive_border" = "rgb(3c3836)"; # gray1
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
        "nm-applet --indicator"
        "waybar"
        "mako"
      ];

      # Keybindings (i3-like)
      bind = [
        # Core actions
        "$mod, Return, exec, wezterm"
        "$mod, D, exec, wofi --show drun,run"
        "$mod SHIFT, Q, killactive,"
        "$mod SHIFT, C, exec, hyprctl reload"
        "$mod SHIFT, R, exec, hyprctl reload"
        "$mod SHIFT, E, exit,"

        # Window state
        "$mod, F, fullscreen, 0"
        "$mod SHIFT, Space, togglefloating,"

        # Focus movement (arrows)
        "$mod, left, movefocus, l"
        "$mod, down, movefocus, d"
        "$mod, up, movefocus, u"
        "$mod, right, movefocus, r"

        # Focus movement (vim keys)
        "$mod, H, movefocus, l"
        "$mod, J, movefocus, d"
        "$mod, K, movefocus, u"
        "$mod, L, movefocus, r"

        # Move windows (Shift + arrows)
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, down, movewindow, d"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, right, movewindow, r"

        # Move windows (Shift + vim keys)
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, J, movewindow, d"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, L, movewindow, r"

        # Workspaces 1-10 (0 = 10)
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Workspaces 11-20 with Ctrl modifier (0 = 20)
        "$mod CTRL, 1, workspace, 11"
        "$mod CTRL, 2, workspace, 12"
        "$mod CTRL, 3, workspace, 13"
        "$mod CTRL, 4, workspace, 14"
        "$mod CTRL, 5, workspace, 15"
        "$mod CTRL, 6, workspace, 16"
        "$mod CTRL, 7, workspace, 17"
        "$mod CTRL, 8, workspace, 18"
        "$mod CTRL, 9, workspace, 19"
        "$mod CTRL, 0, workspace, 20"

        # Move active to workspace 1-10
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # Move active to workspace 11-20 with Ctrl modifier
        "$mod CTRL SHIFT, 1, movetoworkspace, 11"
        "$mod CTRL SHIFT, 2, movetoworkspace, 12"
        "$mod CTRL SHIFT, 3, movetoworkspace, 13"
        "$mod CTRL SHIFT, 4, movetoworkspace, 14"
        "$mod CTRL SHIFT, 5, movetoworkspace, 15"
        "$mod CTRL SHIFT, 6, movetoworkspace, 16"
        "$mod CTRL SHIFT, 7, movetoworkspace, 17"
        "$mod CTRL SHIFT, 8, movetoworkspace, 18"
        "$mod CTRL SHIFT, 9, movetoworkspace, 19"
        "$mod CTRL SHIFT, 0, movetoworkspace, 20"

        # Scratchpad (i3-like special workspace)
        "$mod, minus, togglespecialworkspace,"
        "$mod SHIFT, minus, movetoworkspacesilent, special"

        # Resize mode (i3-like): enter submap
        "$mod, R, submap, resize"
      ];

      # Mouse: Sway's floating modifier behavior
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
    
    # Additional raw config for submaps (ordering-sensitive)
    extraConfig = ''
      # Resize submap
      submap=resize
      # arrows
      binde=,left,resizeactive,-10 0
      binde=,right,resizeactive,10 0
      binde=,up,resizeactive,0 -10
      binde=,down,resizeactive,0 10
      # vim keys
      binde=,H,resizeactive,-10 0
      binde=,L,resizeactive,10 0
      binde=,K,resizeactive,0 -10
      binde=,J,resizeactive,0 10
      # exit
      bind=,escape,submap,reset
      bind=,return,submap,reset
      # back to default submap
      submap=reset
    '';
  };
}
