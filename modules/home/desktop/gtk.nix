{ ... }:
{
  flake.modules.homeManager."desktop.gtk" =
    { pkgs, ... }:
    {
      # Enforce a dark GTK theme for GTK3/GTK4 apps (Plasma and Sway)
      gtk = {
        enable = true;

        # Use Breeze-Dark to align with Plasma's Breeze Dark
        theme = {
          name = "Breeze-Dark";
          package = pkgs.kdePackages.breeze-gtk;
        };

        # Keep icon/cursor consistent with the rest of the setup
        iconTheme = {
          name = "Tela";
          package = pkgs.tela-icon-theme;
        };
        cursorTheme = {
          name = "Breeze";
          package = pkgs.kdePackages.breeze;
        };

        # Prefer dark variant where supported
        gtk3.extraConfig = {
          "gtk-application-prefer-dark-theme" = 1;
        };
        gtk4.extraConfig = {
          "gtk-application-prefer-dark-theme" = true;
        };
      };

      # Hint to libadwaita/GTK apps that support the GNOME color-scheme key
      dconf.settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "Breeze-Dark";
      };
    };
}
