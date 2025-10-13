{ config, ... }:
{
  programs.plasma = {
    enable = true;
    workspace = {
      # Shared wallpaper and theme across hosts
      wallpaper = "${config.home.homeDirectory}/.local/share/wallpapers/13-Ventura-Dark.jpg";
      colorScheme = "MacVentura-Dark";

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
}

