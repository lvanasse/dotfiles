{ lib, ... }:
let
  storageBackedUnits = [
    "docker-sonarr"
    "docker-radarr"
    "docker-bazarr"
    "docker-lidarr"
    "docker-prowlarr"
    "docker-jellyseerr"
    "docker-qbittorrent"
    "docker-calibre"
  ];
in
{
  flake.modules.nixos."services.arr" =
    { ... }:
    {
      # Sonarr - TV shows
      virtualisation.oci-containers.containers.sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
        volumes = [
          "/mnt/data3/appdata/sonarr:/config"
          "/mnt/storage/data:/data"
        ];
        ports = [ "8989:8989" ];
      };

      # Radarr - Movies
      virtualisation.oci-containers.containers.radarr = {
        image = "lscr.io/linuxserver/radarr";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
        volumes = [
          "/mnt/data3/appdata/radarr:/config"
          "/mnt/storage/data:/data"
        ];
        ports = [ "7878:7878" ];
      };

      # Bazarr - Subtitles
      virtualisation.oci-containers.containers.bazarr = {
        image = "lscr.io/linuxserver/bazarr:latest";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
        volumes = [
          "/mnt/data3/appdata/bazarr:/config"
          "/mnt/storage/data:/data"
        ];
        ports = [ "6767:6767" ];
      };

      # Lidarr - Music
      virtualisation.oci-containers.containers.lidarr = {
        image = "lscr.io/linuxserver/lidarr:latest";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
        volumes = [
          "/mnt/data3/appdata/lidarr:/config"
          "/mnt/storage/data:/data"
        ];
        ports = [ "8686:8686" ];
      };

      # Prowlarr - Indexer manager
      virtualisation.oci-containers.containers.prowlarr = {
        image = "lscr.io/linuxserver/prowlarr";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
        volumes = [
          "/mnt/data3/appdata/prowlarr:/config"
        ];
        ports = [ "9696:9696" ];
      };

      # Jellyseerr - Request management
      virtualisation.oci-containers.containers.jellyseerr = {
        image = "fallenbagel/jellyseerr:latest";
        environment = {
          LOG_LEVEL = "info";
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
        volumes = [
          "/mnt/data3/appdata/jellyseerr:/app/config"
        ];
        ports = [ "5055:5055" ];
      };

      # qBittorrent
      virtualisation.oci-containers.containers.qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent:5.1.0";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
          WEBUI_PORT = "8081";
          TORRENTING_PORT = "59793";
        };
        volumes = [
          "/mnt/storage/appdata/qbittorrent:/config"
          "/mnt/storage/data:/data"
          "/mnt/storage/data/torrents:/data/torrents"
          "/mnt/storage/data/torrents:/downloads"
        ];
        extraOptions = [
          "--label=com.centurylinklabs.watchtower.enable=false"
        ];
        ports = [
          "8081:8081"
          "59793:59793"
          "59793:59793/udp"
        ];
      };

      # Calibre
      virtualisation.oci-containers.containers.calibre = {
        image = "lscr.io/linuxserver/calibre";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
        volumes = [
          "/mnt/storage/data/media/books/calibre_library/calibre_libary:/config"
        ];
        ports = [
          "8780:8080"
          "8781:8181"
          "8981:8081"
        ];
      };

      # Flaresolverr - Cloudflare bypass
      virtualisation.oci-containers.containers.flaresolverr = {
        image = "flaresolverr/flaresolverr";
        environment = {
          LOG_LEVEL = "info";
          TZ = "UTC";
        };
        ports = [ "8191:8191" ];
      };

      # Ensure storage pool is mounted before media containers start.
      systemd.services = lib.genAttrs storageBackedUnits (
        _: {
          requires = [
            "mnt-data3.mount"
            "mnt-storage.mount"
          ];
          after = [
            "mnt-data3.mount"
            "mnt-storage.mount"
          ];
        }
      );

      networking.firewall.allowedTCPPorts = [
        8989
        7878
        6767
        8686
        9696
        5055
        8081
        59793
        8780
        8781
        8981
        8191
      ];
      networking.firewall.allowedUDPPorts = [ 59793 ];
    };
}
