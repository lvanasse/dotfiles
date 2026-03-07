{ config, ... }:
let
  flakeConfig = config;
in
{
  flake.modules.homeManager."desktop.sway" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        flakeConfig.flake.modules.homeManager."programs.waybar"
        flakeConfig.flake.modules.homeManager."programs.waybar-sway"
        flakeConfig.flake.modules.homeManager."programs.wofi"
        flakeConfig.flake.modules.homeManager."programs.mako"
        flakeConfig.flake.modules.homeManager."programs.sway-tools"
        flakeConfig.flake.modules.homeManager."programs.rofi"
        flakeConfig.flake.modules.homeManager."programs.swayidle"
      ];

      # Sway-specific packages and Wayland tooling
      home.packages = with pkgs; [
        wl-clipboard
        sway-contrib.grimshot
        swappy
        satty
        grim
        slurp
        swaybg
        swayidle
        swaylock
        wdisplays
        nwg-displays
        rofi
        wofi
        mako
        xdg-desktop-portal-wlr
        gst_all_1.gstreamer
        gst_all_1."gst-plugins-base"
        gst_all_1."gst-plugins-good"
        gst_all_1."gst-plugins-bad"
        gst_all_1."gst-plugins-ugly"
        gst_all_1."gst-libav"
      ];

      # Portals for Wayland screencast (needed by Kooha on non-NixOS hm-only)
      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-wlr
          xdg-desktop-portal-gtk
        ];
        config = {
          sway = {
            default = lib.mkForce "wlr;gtk";
          };
        };
      };

      # Ensure xdg-desktop-portal routes screencast/screenshot to the wlr backend.
      xdg.configFile."xdg-desktop-portal/sway-portals.conf".text = ''
        [preferred]
        default=gtk
        org.freedesktop.impl.portal.Screenshot=wlr
        org.freedesktop.impl.portal.ScreenCast=wlr
      '';

      # Force a known chooser for xdg-desktop-portal-wlr (avoids missing PATH issues).
      xdg.configFile."xdg-desktop-portal-wlr/config".text = ''
        [screencast]
        chooser_type=simple
        chooser_cmd=${pkgs.slurp}/bin/slurp -f %o -or
      '';

      # Ensure the wallpaper file is present in the user's home
      home.file.".local/share/wallpapers/1458678242783.jpg".source =
        ../../../wallpapers/1458678242783.jpg;

      # User session entry for display managers on non-NixOS (e.g., Ubuntu)
      # On non-NixOS, we need to use system graphics drivers via __EGL_VENDOR_LIBRARY_FILENAMES
      home.file.".local/share/wayland-sessions/sway.desktop".text = ''
        [Desktop Entry]
        Name=Sway
        Comment=Wayland compositor
        Exec=${config.wayland.windowManager.sway.package}/bin/sway
        TryExec=${config.wayland.windowManager.sway.package}/bin/sway
        Type=Application
        DesktopNames=sway
        X-GDM-SessionRegister=true
      '';

      # Wrapper script to launch sway with proper graphics driver setup on non-NixOS
      home.file.".local/bin/sway-launch" = {
        executable = true;
        text = ''
          #!/bin/sh
          # Use system EGL/Mesa on non-NixOS to avoid graphics driver incompatibilities
          export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
          export LIBGL_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri
          export LIBVA_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri
          exec ${config.wayland.windowManager.sway.package}/bin/sway "$@"
        '';
      };

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
              command =
                "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE";
              always = true;
            }
            {
              command = "${pkgs.systemd}/bin/systemctl --user restart mako.service";
              always = true;
            }
            {
              command = "swaybg -i ${config.home.homeDirectory}/.local/share/wallpapers/1458678242783.jpg -m fill";
              always = true;
            }
            {
              command = "nm-applet --indicator";
              always = true;
            }
            {
              command =
                "${pkgs.bash}/bin/bash -lc 'if ${pkgs.procps}/bin/pgrep -x waybar >/dev/null 2>&1; then ${pkgs.procps}/bin/pkill -USR2 -x waybar; else exec ${pkgs.waybar}/bin/waybar -c ${config.home.homeDirectory}/.config/waybar/config-sway.jsonc -s ${config.home.homeDirectory}/.config/waybar/style-sway.css; fi'";
              always = true;
            }
            {
              command = "${pkgs.systemd}/bin/systemctl --user restart kanshi";
              always = true;
            }
            # Autostart chat apps (Slack + Discord/Vesktop) at login
            {
              command = "start-chat-apps";
              always = false;
            }
            {
              command = "swaymsg workspace 1";
              always = true;
            }
          ];

          # Keyboard: US International with dead keys
          input = {
            "type:keyboard" = {
              xkb_layout = "us";
              xkb_variant = "intl";
            };
            "type:touchpad" = {
              tap = "enabled";
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
            # Keep compositor-drawn titlebars with a thin surrounding border
            titlebar = true;
            border = 0;
          };

          # Colors sourced from shared theme (Gruvbox Dark Hard)
          colors = config.theme.sway;

          keybindings =
            let
              mod = "Mod4";
            in
            lib.mkDefault {
              # Launchers
              "${mod}+Return" = "exec ${config.wayland.windowManager.sway.config.terminal}";
              "${mod}+d" = "exec rofi-combi";
              "${mod}+Shift+d" = "exec rofi-run-only";
              "${mod}+Shift+q" = "kill";
              "${mod}+Shift+c" = "reload";
              # Reload Sway config (Waybar restarts via exec_always)
              "${mod}+Shift+r" = "exec swaymsg reload";
              "Ctrl+${mod}+r" = "restart";
              "${mod}+Shift+e" = "exec swaynag -t warning -m 'Exit Sway?' -b 'Yes, exit' 'swaymsg exit'";
              "Ctrl+Shift+e" =
                "exec swaynag -t warning -m 'Exit Sway?' -b 'Yes, exit' 'swaymsg exit'";

              # Session
              "${mod}+Shift+x" = "exec swaylock-pixelate";
              # Window state
              "${mod}+f" = "fullscreen toggle";
              "${mod}+Shift+space" = "floating toggle";
              "${mod}+space" = "focus mode_toggle";
              "${mod}+a" = "focus parent";
              "${mod}+r" = "mode \"resize\"";

              # Focus movement (arrows)
              "${mod}+Left" = "focus left";
              "${mod}+Down" = "focus down";
              "${mod}+Up" = "focus up";
              "${mod}+Right" = "focus right";

              # Focus movement (vim-style)
              "${mod}+j" = "focus down";
              "${mod}+k" = "focus up";
              "${mod}+l" = "focus right";

              # Split orientation
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

              # Screenshots (always annotate)
              "Print" = "exec screenshot-annotate";
              "Shift+Print" = "exec screenshot-annotate";
              "Ctrl+Print" = "exec screenshot-annotate";
              # GUI screenshot with selection + annotation (satty; swappy fallback)
              "${mod}+Print" = "exec screenshot-annotate";
              # Screen recording (GUI) - use desktop entry to match Wofi launch
              "${mod}+Shift+Print" = "exec gtk-launch io.github.seadve.Kooha";

              # Layouts
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

          modes = {
            resize = {
              "Left" = "resize shrink width 10 px or 10 ppt";
              "Down" = "resize grow height 10 px or 10 ppt";
              "Up" = "resize shrink height 10 px or 10 ppt";
              "Right" = "resize grow width 10 px or 10 ppt";

              "h" = "resize shrink width 10 px or 10 ppt";
              "j" = "resize grow height 10 px or 10 ppt";
              "k" = "resize shrink height 10 px or 10 ppt";
              "l" = "resize grow width 10 px or 10 ppt";
              "semicolon" = "resize grow width 10 px or 10 ppt";

              "Return" = "mode default";
              "Escape" = "mode default";
            };
          };

          assigns = {
            # Workspace assignments
            # 10: Audio (Pavucontrol)
            "10" = [
              # Pavucontrol for quick audio adjustments
              { class = "Pavucontrol"; }
              { class = "pavucontrol"; }
            ];

            # 11: Chat (Slack, Discord/Vesktop)
            "11" = [
              # Vesktop/Discord (Wayland/Xwayland)
              { app_id = "vesktop"; }
              { class = "Vesktop"; }
              { app_id = "discord"; }
              { class = "discord"; }
              # Slack (Wayland/Xwayland)
              { app_id = "Slack"; }
              { class = "Slack"; }
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
          titlebar_border_thickness 0
          # Ensure titlebars render (pixel 0 disables them)
          default_border normal
          default_floating_border normal

          # Focus windows when the mouse enters them
          focus_follows_mouse yes

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

          # Firefox: no compositor border
          for_window [app_id="firefox"] border pixel 0
          for_window [class="Firefox"] border pixel 0
        '';
      };
    };
}
