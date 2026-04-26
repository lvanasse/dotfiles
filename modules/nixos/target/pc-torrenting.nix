{ ... }:
{
  flake.modules.nixos."target.config.pc.torrenting" =
    { pkgs, ... }:
    {
      # Firewall for torrenting
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [
          59793
          47984
          47985
          47986
          47987
          47988
          47989
          47990
          48010
        ];
      };

      # qBittorrent service
      systemd.user.services.qbittorrent-tray = {
        description = "qBittorrent (GUI, tray only)";
        after = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.qbittorrent}/bin/qbittorrent --no-splash";
          Restart = "on-abort";
        };
      };
    };
}
