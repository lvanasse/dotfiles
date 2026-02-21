{ ... }:
{
  flake.modules.nixos."server.arr" =
    { ... }:
    {
      # Sonarr - TV shows
      virtualisation.oci-containers.containers.sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest";
        environment = {
          PUID = "1000";
          PGID = "1000";
          UMASK = "022";
        };
        volumes = [
          "/var/lib/sonarr:/config"
          "/mnt/storage/data:/data"
        ];
        ports = [ "8989:8989" ];
      };

      # Radarr - Movies
      virtualisation.oci-containers.containers.radarr = {
        image = "lscr.io/linuxserver/radarr:latest";
        environment = {
          PUID = "1000";
          PGID = "1000";
          UMASK = "022";
        };
        volumes = [
          "/var/lib/radarr:/config"
          "/mnt/storage/data:/data"
        ];
        ports = [ "7878:7878" ];
      };

      # Bazarr - Subtitles
      virtualisation.oci-containers.containers.bazarr = {
        image = "lscr.io/linuxserver/bazarr:latest";
        environment = {
          PUID = "1000";
          PGID = "1000";
          UMASK = "022";
        };
        volumes = [
          "/var/lib/bazarr:/config"
          "/mnt/storage/data:/data"
        ];
        ports = [ "6767:6767" ];
      };

      # Readarr - Books
      virtualisation.oci-containers.containers.readarr = {
        image = "lscr.io/linuxserver/readarr:develop";
        environment = {
          PUID = "1000";
          PGID = "1000";
          UMASK = "022";
        };
        volumes = [
          "/var/lib/readarr:/config"
          "/mnt/storage/data:/data"
        ];
        ports = [ "8787:8787" ];
      };

      # Prowlarr - Indexer manager
      virtualisation.oci-containers.containers.prowlarr = {
        image = "lscr.io/linuxserver/prowlarr:latest";
        environment = {
          PUID = "1000";
          PGID = "1000";
          UMASK = "022";
        };
        volumes = [
          "/var/lib/prowlarr:/config"
        ];
        ports = [ "9696:9696" ];
      };

      # Jellyseerr - Request management
      virtualisation.oci-containers.containers.jellyseerr = {
        image = "fallenbagel/jellyseerr:latest";
        environment = {
          PUID = "1000";
          PGID = "1000";
          UMASK = "022";
        };
        volumes = [
          "/var/lib/jellyseerr:/app/config"
        ];
        ports = [ "5055:5055" ];
      };

      # qBittorrent
      virtualisation.oci-containers.containers.qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent:latest";
        environment = {
          PUID = "1000";
          PGID = "1000";
          UMASK = "022";
          WEBUI_PORT = "8080";
          TORRENTING_PORT = "6881";
        };
        volumes = [
          "/var/lib/qbittorrent:/config"
          "/mnt/storage/data:/data"
        ];
        ports = [
          "8080:8080"
          "6881:6881"
          "6881:6881/udp"
        ];
      };

      # Calibre
      virtualisation.oci-containers.containers.calibre = {
        image = "lscr.io/linuxserver/calibre:latest";
        environment = {
          PUID = "1000";
          PGID = "1000";
          UMASK = "022";
        };
        volumes = [
          "/var/lib/calibre:/config"
          "/mnt/storage/data/books:/books"
        ];
        ports = [
          "8083:8080"
          "8181:8181"
          "8081:8081"
        ];
      };

      # Flaresolverr - Cloudflare bypass
      virtualisation.oci-containers.containers.flaresolverr = {
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        environment = {
          LOG_LEVEL = "info";
        };
        ports = [ "8191:8191" ];
      };

      networking.firewall.allowedTCPPorts = [
        8989 7878 6767 8787 9696 5055 8080 8083 8181 8081 8191
      ];
    };
}
