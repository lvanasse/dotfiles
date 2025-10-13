{ config, ... }:
{
  programs.plasma = {
    enable = true;
    workspace = {
      # Shared wallpaper and theme across hosts
      wallpaper = "${config.home.homeDirectory}/.local/share/wallpapers/13-Ventura-Dark.jpg";
      # Use MacVentura Dark assets installed via KDE Store
      colorScheme = "MacVenturaDark";
      theme = "MacVentura-Dark";

      # Requested theming via plasma-manager
      iconTheme = "Tela-dark";
      cursor = {
        theme = "WhiteSur-cursors";
      };
      # Window decorations (Aurorae MacVentura-Dark from KDE Store)
      windowDecorations = {
        library = "org.kde.kwin.aurorae";
        theme = "__aurorae__svg__MacVentura-Dark";
      };
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
}
