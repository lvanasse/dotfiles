{ ... }:
{
  programs.plasma = {
    enable = true;
    workspace = {
      # Requested theming via plasma-manager
      iconTheme = "Tela-dark";
      cursor = {
        theme = "WhiteSur-cursors";
      };
      splashScreen.theme = "MacVentura-dark";
    };

    kwin = {
      # Disable edge barrier so the pointer can cross screens freely
      edgeBarrier = 0;
      cornerBarrier = false;
    };
  };
}
