{ ... }:
{
  flake.modules.nixos."services.jellyfin" =
    { ... }:
    {
      virtualisation.oci-containers.containers.jellyfin = {
        image = "lscr.io/linuxserver/jellyfin:latest";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
          JELLYFIN_PublishedServerUrl = "192.168.0.50";
        };
        volumes = [
          "/mnt/storage/appdata/jellyfin:/config"
          "/mnt/storage/data:/data"
        ];
        ports = [
          "8096:8096"
          "8920:8920"
          "7359:7359/udp"
          "1900:1900/udp"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 8096 8920 ];
      networking.firewall.allowedUDPPorts = [ 7359 1900 ];
    };
}
