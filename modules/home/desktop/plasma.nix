{ ... }:
{
  flake.modules.homeManager."desktop.kde" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
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
    };
}
