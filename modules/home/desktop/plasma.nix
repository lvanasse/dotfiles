{ config, ... }:
{
  programs.plasma = {
    enable = true;
    workspace = {
      # Shared wallpaper and theme across hosts
      wallpaper = "${config.home.homeDirectory}/.local/share/wallpapers/1458678242783.jpg";
      # Breeze Dark across Plasma for a lean, native setup
      colorScheme = "Breeze Dark";
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
        ColorScheme = "Breeze Dark";
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
}
