{ ... }:
{
  flake.modules.homeManager."desktop.kde" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      plasmaRefreshShell = pkgs.writeShellApplication {
        name = "plasma-refresh-shell";
        runtimeInputs = [ pkgs.systemd ];
        text = ''
          if [ "''${1:-}" = "--automatic" ]; then
            screen_active="$(busctl --user call org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver GetActive 2>/dev/null || true)"
            if [ "$screen_active" != "b true" ]; then
              exit 0
            fi
          fi

          if ! systemctl --user --quiet is-active plasma-plasmashell.service; then
            exit 0
          fi

          systemctl --user restart plasma-plasmashell.service
        '';
      };

      plasmaRefreshShellOnResume = pkgs.writeShellApplication {
        name = "plasma-refresh-shell-on-resume";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.dbus
          pkgs.systemd
        ];
        text = ''
          state_dir="''${XDG_RUNTIME_DIR:-/tmp}/plasma-refresh-shell"
          last_refresh="$state_dir/last-refresh"
          mkdir -p "$state_dir"

          refresh_shell() {
            now="$(${pkgs.coreutils}/bin/date +%s)"
            previous=0
            if [ -r "$last_refresh" ]; then
              previous="$(${pkgs.coreutils}/bin/cat "$last_refresh" 2>/dev/null || printf 0)"
            fi

            if [ "$((now - previous))" -lt 30 ]; then
              return 0
            fi

            printf '%s\n' "$now" > "$last_refresh"
            ${pkgs.coreutils}/bin/sleep 5

            if ${pkgs.systemd}/bin/systemctl --user --quiet is-active plasma-plasmashell.service; then
              ${pkgs.systemd}/bin/systemctl --user restart plasma-plasmashell.service
            fi
          }

          monitor_unlock() {
            while true; do
              ${pkgs.dbus}/bin/dbus-monitor --session \
                "type='signal',interface='org.freedesktop.ScreenSaver',member='ActiveChanged'" |
                while IFS= read -r line; do
                  case "$line" in
                    *"boolean false"*) refresh_shell ;;
                  esac
                done
              ${pkgs.coreutils}/bin/sleep 5
            done
          }

          monitor_resume() {
            while true; do
              ${pkgs.dbus}/bin/dbus-monitor --system \
                "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" |
                while IFS= read -r line; do
                  case "$line" in
                    *"boolean false"*) refresh_shell ;;
                  esac
                done
              ${pkgs.coreutils}/bin/sleep 5
            done
          }

          monitor_unlock &
          monitor_resume &
          wait
        '';
      };
    in
    {
      # KDE applications and theming
      home.packages =
        (with pkgs.kdePackages; [
          dolphin
          filelight
          spectacle
          polkit-kde-agent-1
          xdg-desktop-portal-kde
          sddm-kcm
        ])
        ++ (with pkgs; [
          tela-icon-theme
          whitesur-cursors
        ])
        ++ [
          plasmaRefreshShell
        ]
        ++ lib.optional (pkgs.kdePackages ? xwaylandvideobridge) pkgs.kdePackages.xwaylandvideobridge;

      programs.plasma = {
        enable = true;
        workspace = {
          # Shared wallpaper and theme across hosts
          wallpaper = "${config.home.homeDirectory}/.local/share/wallpapers/1458678242783.jpg";
          # Breeze Dark across Plasma for a lean, native setup
          colorScheme = "BreezeDark";
          theme = "breeze-dark"; # Plasma style

          # Icon theme
          iconTheme = "Tela";
          cursor = {
            theme = "Breeze";
          };
          # Breeze window decorations (fast, upstream-maintained)
          windowDecorations = {
            library = "org.kde.kdecoration2";
            theme = "Breeze";
          };
        };

        # KWin options
        kwin = {
          # Disable edge barrier so the pointer can cross screens freely
          edgeBarrier = 0;
          cornerBarrier = false;
        };

        # KDE settings tuned for responsiveness
        configFile = {
          # Default terminal integration
          "kdeglobals"."General" = {
            TerminalApplication = "wezterm";
            TerminalService = "org.wezfurlong.wezterm.desktop";
            # Ensure apps pick the Breeze Dark color scheme
            ColorScheme = "BreezeDark";
          };
          # Global Look & Feel + faster animations
          "kdeglobals"."KDE" = {
            LookAndFeelPackage = "org.kde.breezedark.desktop";
            # Lower means faster/shorter animations (1.0 = default)
            AnimationDurationFactor = 0.4;
          };
          # Icon theme
          "kdeglobals"."Icons".Theme = "Tela";
          # Plasma style (panel/desktop theme)
          "plasmarc"."Theme".name = "breeze-dark";
          # Cursor theme
          "kcminputrc"."Mouse".cursorTheme = "Breeze";
          # KWin: disable costly effects to minimize latency
          "kwinrc"."Plugins" = {
            kwin4_effect_blurEnabled = false;
            kwin4_effect_backgroundcontrastEnabled = false;
          };
          # KWin: prefer stable OpenGL settings where applicable
          "kwinrc"."Compositing" = {
            OpenGLIsUnsafe = false;
          };
        };
      };

      # Ensure the wallpaper file is present in the user's home
      home.file.".local/share/wallpapers/1458678242783.jpg".source =
        ../../../wallpapers/1458678242783.jpg;

      xdg.configFile =
        lib.genAttrs
          [
            "systemd/user/drkonqi-coredump-launcher.socket"
            "systemd/user/drkonqi-coredump-launcher@.service"
            "systemd/user/drkonqi-coredump-pickup.service"
            "systemd/user/drkonqi-sentry-postman.path"
          ]
          (_: {
            source = config.lib.file.mkOutOfStoreSymlink "/dev/null";
          });

      systemd.user.services.plasma-session-environment = {
        Unit = {
          Description = "Refresh Plasma session environment";
          PartOf = [ "plasma-workspace.target" ];
          Before = [ "xdg-desktop-autostart.target" ];
        };

        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.bash}/bin/bash -lc '${pkgs.systemd}/bin/systemctl --user stop sway-session.target 2>/dev/null || true; ${pkgs.systemd}/bin/systemctl --user unset-environment SWAYSOCK I3SOCK; ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd PATH XDG_DATA_DIRS XDG_CONFIG_DIRS DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE DESKTOP_SESSION KDE_FULL_SESSION KDE_SESSION_VERSION; ${pkgs.systemd}/bin/systemctl --user restart xdg-desktop-portal.service 2>/dev/null || true'";
        };

        Install.WantedBy = [ "plasma-workspace.target" ];
      };

      systemd.user.services.plasma-refresh-shell = {
        Unit = {
          Description = "Refresh Plasma Shell";
          Documentation = [ "man:plasmashell(1)" ];
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${plasmaRefreshShell}/bin/plasma-refresh-shell --automatic";
        };
      };

      systemd.user.timers.plasma-refresh-shell = {
        Unit = {
          Description = "Periodically refresh Plasma Shell to recover stale task manager icons";
        };

        Timer = {
          OnCalendar = "hourly";
          RandomizedDelaySec = "15m";
        };

        Install.WantedBy = [ "timers.target" ];
      };

      systemd.user.services.plasma-refresh-shell-on-resume = {
        Unit = {
          Description = "Refresh Plasma Shell after unlock or resume";
          PartOf = [ "plasma-workspace.target" ];
          After = [ "plasma-workspace.target" ];
        };

        Service = {
          ExecStart = "${plasmaRefreshShellOnResume}/bin/plasma-refresh-shell-on-resume";
          Restart = "always";
          RestartSec = 10;
        };

        Install.WantedBy = [ "plasma-workspace.target" ];
      };
    };
}
