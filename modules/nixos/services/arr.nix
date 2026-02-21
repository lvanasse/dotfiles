{ ... }:
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
          "/mnt/storage/appdata/sonarr:/config"
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
          "/mnt/storage/appdata/radarr:/config"
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
          "/mnt/storage/appdata/bazarr:/config"
          "/mnt/storage/data:/data"
        ];
        ports = [ "6767:6767" ];
      };

      # Readarr - Books
      virtualisation.oci-containers.containers.readarr = {
        image = "ghcr.io/hotio/readarr:latest";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "002";
          PRIVOXY_ENABLED = "false";
          UNBOUND_ENABLED = "false";
          VPN_ENABLED = "false";
          VPN_CONF = "wg0";
          VPN_PROVIDER = "generic";
          VPN_AUTO_PORT_FORWARD = "true";
          VPN_KEEP_LOCAL_DNS = "false";
          VPN_FIREWALL_TYPE = "auto";
          VPN_PIA_DIP_TOKEN = "no";
          VPN_PIA_PORT_FORWARD_PERSIST = "false";
        };
        volumes = [
          "/mnt/storage/appdata/readarr:/config"
          "/mnt/storage/data:/data"
        ];
        ports = [ "8787:8787" ];
        extraOptions = [
          "--hostname=readarr.internal"
          "--cap-add=NET_ADMIN"
          "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
          "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
        ];
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
          "/mnt/storage/appdata/prowlarr:/config"
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
          "/mnt/storage/appdata/jellyseerr:/app/config"
        ];
        ports = [ "5055:5055" ];
      };

      # qBittorrent
      virtualisation.oci-containers.containers.qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
          WEBUI_PORT = "8080";
          TORRENTING_PORT = "6881";
        };
        volumes = [
          "/mnt/storage/appdata/qbittorrent:/config"
          "/mnt/storage/data:/data"
          "/mnt/storage/data/torrents:/data/torrents"
        ];
        ports = [
          "8080:8080"
          "6881:6881"
          "6881:6881/udp"
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

      networking.firewall.allowedTCPPorts = [
        8989 7878 6767 8787 9696 5055 8080 6881 8780 8781 8981 8191
      ];
      networking.firewall.allowedUDPPorts = [ 6881 ];
    };
}
