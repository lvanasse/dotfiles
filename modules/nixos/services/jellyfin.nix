{ ... }:
{
  flake.modules.nixos."services.jellyfin" =
    { ... }:
    let
      appDataRoot = "/mnt/ssd/appdata/docker/jellyfin";
      transcodesRoot = "/mnt/ssd/scratch/transcodes/jellyfin";
      hotMediaRoot = "/mnt/ssd/scratch/hot-media";
      moviesRoot = "/mnt/storage/data/media/movies";
      showsRoot = "/mnt/storage/data/media/tv";
    in
    {
      virtualisation.oci-containers.containers.jellyfin = {
        image = "lscr.io/linuxserver/jellyfin:latest";
        devices = [ "/dev/dri:/dev/dri" ];
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
          JELLYFIN_PublishedServerUrl = "https://jellyfin.ludovicvanasse.com";
        };
        volumes = [
          "${appDataRoot}/config:/config"
          "${appDataRoot}/cache:/cache"
          "${transcodesRoot}:/transcodes"
          "/mnt/storage/data:/data"
          "${moviesRoot}:/media/Movies:ro"
          "${showsRoot}:/media/Shows:ro"
          "${hotMediaRoot}:/hot-media:ro"
        ];
        ports = [
          "8096:8096"
          "8920:8920"
          "7359:7359/udp"
          "1900:1900/udp"
        ];
      };

      networking.firewall.allowedTCPPorts = [
        8096
        8920
      ];
      networking.firewall.allowedUDPPorts = [
        7359
        1900
      ];

      systemd.services.docker-jellyfin = {
        requires = [
          "mnt-ssd.mount"
          "mnt-storage.mount"
        ];
        after = [
          "mnt-ssd.mount"
          "mnt-storage.mount"
        ];
      };
    };
}
