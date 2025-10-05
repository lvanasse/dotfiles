# New modular Home Manager configuration
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ../modules/home
  ];

  # TODO: Move these to appropriate modules when ready
  # Commented out Sway configuration (kept for reference)
  # wayland.windowManager.sway = {
  #   enable = true;
  #   systemd.enable = true; # creates sway‑session.target
  #   config = rec {
  #     modifier = "Mod4";
  #     input = {
  #       "*" = {
  #         xkb_layout = "us";
  #         xkb_variant = "intl";
  #       };
  #     };
  #     terminal = "gnome-terminal";
  #     menu = "bemenu-run -p \"\"";
  #     bars = [ ];
  #   };
  #   extraConfig = "
  #       include ~/.config/sway/outputs
  #       include ~/.config/sway/workspaces
  #     ";
  # };

  # Commented out Stylix configuration (kept for reference)
  # stylix.enable = true;
  # stylix.autoEnable = true;
  # stylix.targets.gnome.enable = false;
  # stylix.image = ../wallpapers/1458678242783.jpg;
  # stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  # stylix.fonts = {
  #   emoji = {
  #     package = pkgs.noto-fonts-emoji-blob-bin;
  #     name = "Noto Emoji with extended Blob support";
  #   };
  # };

  # Commented out Mako configuration (kept for reference)
  # services.mako.enable = false;
  # systemd.user.services.mako = {
  #   Unit = {
  #     Description = "Mako notification daemon (Wayland WMs only)";
  #     PartOf = [
  #       "sway-session.target"
  #     ];
  #     StopWhenUnneeded = true;
  #   };
  #   Service = {
  #     ExecStart = "${pkgs.mako}/bin/mako";
  #     Restart = "on-failure";
  #     Environment = "XDG_CURRENT_DESKTOP=wayland";
  #   };
  #   Install = {
  #     WantedBy = [
  #       "sway-session.target"
  #     ];
  #   };
  # };
}