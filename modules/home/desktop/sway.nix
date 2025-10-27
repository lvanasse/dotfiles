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
          command = "swaybg -i ${config.home.homeDirectory}/.local/share/wallpapers/1458678242783.jpg -m fill";
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
        # Autostart chat apps (Slack + Discord/Vesktop) at login
        {
          command = "start-chat-apps";
          always = false;
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
      # Workspace assignments are defined further below
      # (keep this empty placeholder removed to avoid duplicate definitions)
      bars = [ ]; # use waybar
      window = {
        # Keep compositor-drawn titlebars, but no surrounding border
        titlebar = true;
        border = 0;
      };

      # Colors sourced from shared theme (Gruvbox Dark Hard)
      colors = config.theme.sway;

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
          # Reload Sway config and restart Waybar to pick up changes
          "${mod}+Shift+r" =
            "exec ${pkgs.bash}/bin/bash -lc '${pkgs.procps}/bin/pkill -x waybar >/dev/null 2>&1 || true; swaymsg reload; ${pkgs.util-linux}/bin/setsid -f ${pkgs.waybar}/bin/waybar -c ${config.home.homeDirectory}/.config/waybar/config-sway.jsonc -s ${config.home.homeDirectory}/.config/waybar/style-sway.css >/dev/null 2>&1'";
          "Ctrl+${mod}+r" = "restart";
          "${mod}+Shift+e" = "exec swaynag -t warning -m 'Exit Sway?' -b 'Yes, exit' 'swaymsg exit'";

          # Session
          "${mod}+Shift+x" =
            "exec ${pkgs.swaylock}/bin/swaylock -f -i ${config.home.homeDirectory}/.local/share/wallpapers/1458678242783.jpg -s fill";

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

          # Screenshots
          "Print" = "exec screenshot copy area";
          "Shift+Print" = "exec screenshot save area";
          "Ctrl+Print" = "exec screenshot copy output";
          # GUI screenshot with selection + annotation (grim + slurp + swappy)
          "${mod}+Print" = "exec screenshot-annotate";

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
        # Workspace assignments
        # 10: Chat (Slack, Discord/Vesktop) + audio (Pavucontrol)
        "10" = [
          # Vesktop/Discord (Wayland/Xwayland)
          { app_id = "vesktop"; }
          { class = "Vesktop"; }
          { app_id = "discord"; }
          { class = "discord"; }
          # Slack (Wayland/Xwayland)
          { app_id = "Slack"; }
          { class = "Slack"; }
          # Pavucontrol for quick audio adjustments
          { class = "Pavucontrol"; }
          { class = "pavucontrol"; }
        ];

        # 9: qBittorrent (and mail if running)
        "9" = [
          { class = "qBittorrent"; }
          { app_id = "org.qbittorrent.qBittorrent"; }
          { class = "Thunderbird"; }
        ];

        # 8: IM
        "8" = [ { class = "Pidgin"; } ];
      };
    };

    extraConfig = ''
      # Make Sway titlebars thinner (reduce vertical/horizontal padding)
      # Keep font size; just tighten the chrome a bit
      titlebar_padding 1 4

      # Chat workspace: auto-tab layout when windows appear on workspace 10
      # This avoids focus flashes by not forcing a workspace switch at startup
      for_window [workspace="10"] layout tabbed

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

      # Firefox: ensure no compositor borders; rely on server-side decoration
      for_window [app_id="firefox"] border pixel 0
      for_window [class="Firefox"] border pixel 0
    '';
  };
}
