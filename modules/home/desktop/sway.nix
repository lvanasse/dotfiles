{
  config,
  lib,
  pkgs,
  ...
}:
{
  wayland.windowManager.sway = {
    enable = true;
    systemd.enable = true;
    wrapperFeatures.gtk = true;

    config = {
      modifier = "Mod4";
      terminal = "wezterm";

      # Start background, tray, and Waybar
      startup = [
        {
          command = "swaybg -i ${config.home.homeDirectory}/.local/share/wallpapers/13-Ventura-Dark.jpg -m fill";
          always = true;
        }
        {
          command = "nm-applet --indicator";
          always = true;
        }
        {
          command = "waybar -c ${config.home.homeDirectory}/.config/waybar/config-sway.jsonc -s ${config.home.homeDirectory}/.config/waybar/style-sway.css";
          always = true;
        }
      ];

      # Keyboard: US International with dead keys
      input = {
        "type:keyboard" = {
          xkb_layout = "us";
          xkb_variant = "intl";
        };
      };
      fonts = {
        names = [ "Inter" ];
        size = 8.0;
      };
      gaps = {
        inner = 0;
        outer = 0;
        smartBorders = "on";
        smartGaps = false;
      };
      assigns = { };
      bars = [ ]; # use waybar
      window = {
        titlebar = true;
        border = 2;
      };

      keybindings =
        let
          mod = "Mod4";
        in
        lib.mkOptionDefault {
          # Launchers
          "${mod}+Return" = "exec wezterm";
          "${mod}+d" = "exec rofi-combi";
          "${mod}+Shift+d" = "exec rofi-run-only";
          "${mod}+Shift+q" = "kill";
          "${mod}+Shift+c" = "reload";
          "${mod}+Shift+r" = "reload";
          "Ctrl+${mod}+r" = "restart";
          "${mod}+Shift+e" = "exec swaynag -t warning -m 'Exit Sway?' -b 'Yes, exit' 'swaymsg exit'";

          # Window state
          "${mod}+f" = "fullscreen toggle";
          "${mod}+Shift+space" = "floating toggle";
          "${mod}+space" = "focus mode_toggle";
          "${mod}+a" = "focus parent";

          # Focus movement (arrows)
          "${mod}+Left" = "focus left";
          "${mod}+Down" = "focus down";
          "${mod}+Up" = "focus up";
          "${mod}+Right" = "focus right";

          # Focus movement (vim + i3-style)
          "${mod}+j" = "focus down";
          "${mod}+k" = "focus up";
          "${mod}+l" = "focus right";

          # Split orientation (i3-style)
          "${mod}+h" = "split h";
          "${mod}+v" = "split v";

          # Move windows
          "${mod}+Shift+Left" = "move left";
          "${mod}+Shift+Down" = "move down";
          "${mod}+Shift+Up" = "move up";
          "${mod}+Shift+Right" = "move right";
          "${mod}+Shift+h" = "move left";
          "${mod}+Shift+j" = "move down";
          "${mod}+Shift+k" = "move up";
          "${mod}+Shift+l" = "move right";
          "${mod}+Shift+semicolon" = "move right";

          # Media keys
          "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
          "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
          "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";

          # Layouts (i3-like)
          "${mod}+w" = "layout tabbed";
          "${mod}+s" = "layout stacking";
          "${mod}+e" = "layout toggle split";

          # Scratchpad
          "${mod}+minus" = "scratchpad show";
          "${mod}+Shift+minus" = "move scratchpad";

          # Workspaces 1–10
          "${mod}+1" = "workspace 1";
          "${mod}+2" = "workspace 2";
          "${mod}+3" = "workspace 3";
          "${mod}+4" = "workspace 4";
          "${mod}+5" = "workspace 5";
          "${mod}+6" = "workspace 6";
          "${mod}+7" = "workspace 7";
          "${mod}+8" = "workspace 8";
          "${mod}+9" = "workspace 9";
          "${mod}+0" = "workspace 10";

          # Move to workspaces 1–10
          "${mod}+Shift+1" = "move container to workspace 1";
          "${mod}+Shift+2" = "move container to workspace 2";
          "${mod}+Shift+3" = "move container to workspace 3";
          "${mod}+Shift+4" = "move container to workspace 4";
          "${mod}+Shift+5" = "move container to workspace 5";
          "${mod}+Shift+6" = "move container to workspace 6";
          "${mod}+Shift+7" = "move container to workspace 7";
          "${mod}+Shift+8" = "move container to workspace 8";
          "${mod}+Shift+9" = "move container to workspace 9";
          "${mod}+Shift+0" = "move container to workspace 10";
        };

      assigns = {
        # Workspace assignments (i3-inspired)
        "10" = [
          { class = "Pavucontrol"; }
          { class = "pavucontrol"; }
        ];
        "11" = [
          { app_id = "discord"; }
          { app_id = "vesktop"; }
          { class = "discord"; }
          { class = "Slack"; }
          { app_id = "Slack"; }
        ];
        "9" = [

          { class = "Thunderbird"; }
        ];
        "8" = [ { class = "Pidgin"; } ];
      };
    };

    extraConfig = ''
      # Make Sway titlebars thinner (reduce vertical/horizontal padding)
      # Keep font size; just tighten the chrome a bit
      titlebar_padding 1 4

      # Displays (from sway-export-outputs)
      output DVI-D-1 mode 1920x1080@60Hz
      output DVI-D-1 pos 0 1080
      output DVI-D-1 transform 90
      output HDMI-A-2 mode 1920x1080@60Hz
      output HDMI-A-2 pos 3000 1080
      output HDMI-A-1 mode 1920x1080@60Hz
      output HDMI-A-1 pos 1080 1080
      output DP-2 mode 2560x1080@60Hz
      output DP-2 pos 440 0

      # Treat HDMI-A-1 as the main display by assigning primary workspaces to it
      workspace 1 output HDMI-A-1

      # Workspaces 11–20 using Ctrl modifier
      bindsym Ctrl+Mod4+1 workspace 11
      bindsym Ctrl+Mod4+2 workspace 12
      bindsym Ctrl+Mod4+3 workspace 13
      bindsym Ctrl+Mod4+4 workspace 14
      bindsym Ctrl+Mod4+5 workspace 15
      bindsym Ctrl+Mod4+6 workspace 16
      bindsym Ctrl+Mod4+7 workspace 17
      bindsym Ctrl+Mod4+8 workspace 18
      bindsym Ctrl+Mod4+9 workspace 19
      bindsym Ctrl+Mod4+0 workspace 20

      bindsym Ctrl+Mod4+Shift+1 move container to workspace 11
      bindsym Ctrl+Mod4+Shift+2 move container to workspace 12
      bindsym Ctrl+Mod4+Shift+3 move container to workspace 13
      bindsym Ctrl+Mod4+Shift+4 move container to workspace 14
      bindsym Ctrl+Mod4+Shift+5 move container to workspace 15
      bindsym Ctrl+Mod4+Shift+6 move container to workspace 16
      bindsym Ctrl+Mod4+Shift+7 move container to workspace 17
      bindsym Ctrl+Mod4+Shift+8 move container to workspace 18
      bindsym Ctrl+Mod4+Shift+9 move container to workspace 19
      bindsym Ctrl+Mod4+Shift+0 move container to workspace 20

      # Add only missing bindings to the built-in resize mode to avoid duplicates
      mode "resize" {
        bindsym semicolon resize grow width 10 px or 10 ppt
      }
    '';
  };
}
