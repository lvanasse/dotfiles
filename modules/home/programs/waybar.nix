{ ... }:
{
  flake.modules.homeManager."programs.waybar" =
    {
      config,
      pkgs,
      ...
    }:
    let
      swayTarget = "sway-session.target";
    in
    {
      # Bind Waybar to the Sway session so it is stopped before switching to
      # KDE and automatically restarted if startup races with session services.
      programs.waybar = {
        enable = true;
        systemd.enable = false;
      };

      systemd.user.services.waybar = {
        Unit = {
          Description = "Waybar for Sway";
          PartOf = [ swayTarget ];
          After = [ swayTarget ];
        };
        Service = {
          ExecStart = "${pkgs.waybar}/bin/waybar -c ${config.home.homeDirectory}/.config/waybar/config-sway.jsonc -s ${config.home.homeDirectory}/.config/waybar/style-sway.css";
          ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
          Restart = "on-failure";
          RestartSec = 1;
        };
        Install = {
          WantedBy = [ swayTarget ];
        };
      };
    };
}
