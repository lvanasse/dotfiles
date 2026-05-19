{ inputs, lib, ... }:
let
  arrSecretsAge = "${inputs.secrets}/server/arr-secrets.yml.age";
  arrSecretsPlainRepo = "${inputs.secrets}/server/arr-secrets.yml";
  arrSecretsPlainOverride = ../../../overrides/arr-secrets.yml;
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
  appDataRoots = {
    sonarr = "/mnt/data3/appdata/sonarr";
    radarr = "/mnt/data3/appdata/radarr";
    bazarr = "/mnt/data3/appdata/bazarr";
    lidarr = "/mnt/data3/appdata/lidarr";
    prowlarr = "/mnt/data3/appdata/prowlarr";
    jellyseerr = "/mnt/data3/appdata/jellyseerr";
    qbittorrent = "/mnt/storage/appdata/qbittorrent";
  };
in
{
  flake.modules.nixos."services.arr" =
    { config, pkgs, ... }:
    let
      hasAgeSecrets = builtins.pathExists arrSecretsAge;
      hasPlainSecretsRepo = builtins.pathExists arrSecretsPlainRepo;
      hasPlainSecretsOverride = builtins.pathExists arrSecretsPlainOverride;
      qBittorrentSecretsPath =
        if hasAgeSecrets then
          config.age.secrets."arr-secrets".path
        else if hasPlainSecretsOverride then
          toString arrSecretsPlainOverride
        else if hasPlainSecretsRepo then
          toString arrSecretsPlainRepo
        else
          "/etc/arr-secrets.yml";
      qBittorrentBooksCategoryPath = "/downloads/books";
      qBittorrentAudiobookCategoryPath = "/downloads/audiobook";
      qBittorrentConfigPath = "/mnt/storage/appdata/qbittorrent/qBittorrent/qBittorrent.conf";
      qBittorrentCategoriesPath = "/mnt/storage/appdata/qbittorrent/qBittorrent/categories.json";
      pythonWithYaml = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
      qBittorrentMamConfig = pkgs.writeText "qbittorrent-mam-config.py" ''
        import configparser
        import json
        import os
        import pathlib
        import sys

        config_path = pathlib.Path(sys.argv[1])
        categories_path = pathlib.Path(sys.argv[2])
        config_path.parent.mkdir(parents=True, exist_ok=True)
        categories_path.parent.mkdir(parents=True, exist_ok=True)

        config = configparser.ConfigParser(interpolation=None)
        config.optionxform = str

        if config_path.exists():
          with config_path.open(encoding="utf-8") as fh:
            config.read_file(fh)

        desired = {
          "BitTorrent": {
            r"Session\DHTEnabled": "false",
            r"Session\LSDEnabled": "false",
            r"Session\PeXEnabled": "false",
            r"Session\Port": "59793",
            r"Session\QueueingSystemEnabled": "false",
          },
          "AutoRun": {
            "enabled": "false",
            "program": "",
          },
          "Preferences": {
            r"Connection\PortRangeMin": "59793",
            r"Connection\UPnP": "false",
          },
        }

        changed = False
        for section, entries in desired.items():
          if not config.has_section(section):
            config.add_section(section)
            changed = True
          for key, value in entries.items():
            if config.get(section, key, fallback=None) != value:
              config.set(section, key, value)
              changed = True

        if changed:
          tmp_path = config_path.with_suffix(config_path.suffix + ".tmp")
          with tmp_path.open("w", encoding="utf-8") as fh:
            config.write(fh, space_around_delimiters=False)
          os.replace(tmp_path, config_path)

        categories = {}
        if categories_path.exists():
          with categories_path.open(encoding="utf-8") as fh:
            try:
              categories = json.load(fh)
            except json.JSONDecodeError:
              categories = {}

        if categories.get("books", {}).get("save_path") != "${qBittorrentBooksCategoryPath}":
          categories["books"] = {"save_path": "${qBittorrentBooksCategoryPath}"}
          changed = True

        if categories.get("audiobook", {}).get("save_path") != "${qBittorrentAudiobookCategoryPath}":
          categories["audiobook"] = {"save_path": "${qBittorrentAudiobookCategoryPath}"}
          changed = True

        for obsolete_category in ("cwa", "lazylibrarian"):
          if obsolete_category in categories:
            del categories[obsolete_category]
            changed = True

        if changed:
          tmp_path = categories_path.with_suffix(categories_path.suffix + ".tmp")
          with tmp_path.open("w", encoding="utf-8") as fh:
            json.dump(categories, fh, indent=4, sort_keys=True)
            fh.write("\n")
          os.replace(tmp_path, categories_path)
      '';
      qBittorrentAlwaysSeed = pkgs.writeText "qbittorrent-always-seed.py" ''
        import argparse
        import http.cookiejar
        import json
        import pathlib
        import sys
        import time
        import urllib.parse
        import urllib.request

        import yaml


        ALWAYS_SEED_CATEGORIES = {"books", "audiobook"}
        ALWAYS_SEED_TAGS = {"book", "books", "audiobook", "audiobooks"}


        def read_secrets(path):
          data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
          username = data.get("QBITTORRENT_USER") or data.get("QBITTORRENT_USERNAME")
          password = data.get("QBITTORRENT_PASS") or data.get("QBITTORRENT_PASSWORD")

          if not username or not password:
            raise RuntimeError("missing QBITTORRENT_USER/QBITTORRENT_PASS in {}".format(path))

          return username, password


        def make_opener():
          cookies = http.cookiejar.CookieJar()
          return urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cookies))


        def post(opener, base_url, endpoint, data):
          request = urllib.request.Request(
            base_url + endpoint,
            data=urllib.parse.urlencode(data).encode("utf-8"),
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            method="POST",
          )
          with opener.open(request, timeout=15) as response:
            return response.read().decode("utf-8", errors="replace")


        def get_json(opener, base_url, endpoint):
          with opener.open(base_url + endpoint, timeout=15) as response:
            return json.loads(response.read().decode("utf-8"))


        def torrent_tags(value):
          if isinstance(value, list):
            raw_tags = value
          else:
            raw_tags = str(value or "").split(",")

          return {tag.strip().casefold() for tag in raw_tags if tag and tag.strip()}


        def should_always_seed(torrent):
          category = str(torrent.get("category") or "").casefold()
          tags = torrent_tags(torrent.get("tags"))
          return category in ALWAYS_SEED_CATEGORIES or bool(tags & ALWAYS_SEED_TAGS)


        def reconcile(args):
          secrets_path = pathlib.Path(args.secrets)
          username, password = read_secrets(secrets_path)
          base_url = args.url.rstrip("/")
          opener = make_opener()

          login_response = post(
            opener,
            base_url,
            "/api/v2/auth/login",
            {"username": username, "password": password},
          ).strip()
          if login_response == "Fails.":
            raise RuntimeError("qBittorrent login failed")

          torrents = get_json(opener, base_url, "/api/v2/torrents/info")
          hashes = [torrent["hash"] for torrent in torrents if should_always_seed(torrent)]

          if not hashes:
            print("no book or audiobook torrents matched")
            return

          joined_hashes = "|".join(hashes)
          post(
            opener,
            base_url,
            "/api/v2/torrents/setShareLimits",
            {
              "hashes": joined_hashes,
              "ratioLimit": "-1",
              "seedingTimeLimit": "-1",
              "inactiveSeedingTimeLimit": "-1",
            },
          )
          post(opener, base_url, "/api/v2/torrents/resume", {"hashes": joined_hashes})
          print("set unlimited seeding for {} book/audiobook torrents".format(len(hashes)))


        def main():
          parser = argparse.ArgumentParser()
          parser.add_argument("--url", default="http://127.0.0.1:8081")
          parser.add_argument("--secrets", required=True)
          parser.add_argument("--retries", type=int, default=12)
          parser.add_argument("--retry-delay", type=float, default=5.0)
          args = parser.parse_args()

          for attempt in range(1, args.retries + 1):
            try:
              reconcile(args)
              return
            except Exception as error:
              if attempt == args.retries:
                raise
              print(
                "qBittorrent always-seed attempt {}/{} failed: {}".format(
                  attempt, args.retries, error
                ),
                file=sys.stderr,
              )
              time.sleep(args.retry_delay)


        if __name__ == "__main__":
          main()
      '';
    in
    {
      systemd.tmpfiles.rules = [
        "d ${appDataRoots.sonarr} 0775 99 100 -"
        "d ${appDataRoots.radarr} 0775 99 100 -"
        "d ${appDataRoots.bazarr} 0775 99 100 -"
        "d ${appDataRoots.lidarr} 0775 99 100 -"
        "d ${appDataRoots.prowlarr} 0775 99 100 -"
        "d ${appDataRoots.jellyseerr} 0775 99 100 -"
        "d ${appDataRoots.qbittorrent} 0775 99 100 -"
        "d /mnt/storage/data/torrents/books 0775 99 100 -"
        "d /mnt/storage/data/torrents/audiobook 0775 99 100 -"
      ];

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
          "/mnt/storage/data/torrents:/downloads"
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
          "/mnt/storage/data/torrents:/downloads"
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
          "/mnt/storage/data/torrents:/downloads"
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
      systemd.services =
        (lib.genAttrs storageBackedUnits (_: {
          requires = [
            "mnt-data3.mount"
            "mnt-storage.mount"
          ];
          after = [
            "mnt-data3.mount"
            "mnt-storage.mount"
          ];
        }))
        // {
          # Keep the live WebUI/RSS config, but enforce the MaM-safe tracker settings.
          "docker-qbittorrent".preStart = lib.mkBefore ''
            ${pkgs.python3}/bin/python3 ${qBittorrentMamConfig} \
              ${lib.escapeShellArg qBittorrentConfigPath} \
              ${lib.escapeShellArg qBittorrentCategoriesPath}
          '';

          qbittorrent-always-seed-books = {
            description = "Keep book and audiobook qBittorrent torrents seeding";
            wants = [ "network-online.target" ];
            requires = [ "docker-qbittorrent.service" ];
            after = [
              "docker-qbittorrent.service"
              "network-online.target"
            ];
            serviceConfig = {
              Type = "oneshot";
            };
            script = ''
              ${pythonWithYaml}/bin/python3 ${qBittorrentAlwaysSeed} \
                --url http://127.0.0.1:8081 \
                --secrets ${lib.escapeShellArg qBittorrentSecretsPath}
            '';
          };
        };

      systemd.timers.qbittorrent-always-seed-books = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "3min";
          OnUnitActiveSec = "15min";
          AccuracySec = "1min";
          Unit = "qbittorrent-always-seed-books.service";
        };
      };

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
