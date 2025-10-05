{ inputs, ... }:
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

  # Also provide public SSH keys for reproducibility
  home.file.".ssh/id_ed25519_personal.pub".source = "${inputs.secrets}/keys/id_ed25519_personal.pub";
  home.file.".ssh/id_ed25519_work.pub".source = "${inputs.secrets}/keys/id_ed25519_work.pub";
}
