{ inputs, ... }:
let
  arrSecretsAge = "${inputs.secrets}/server/arr-secrets.yml.age";
  arrSecretsPlainRepo = "${inputs.secrets}/server/arr-secrets.yml";
  arrSecretsPlainOverride = ../../../overrides/arr-secrets.yml;
in
{
  flake.modules.nixos."services.shelfmark" =
    { config, pkgs, ... }:
    let
      hasAgeSecrets = builtins.pathExists arrSecretsAge;
      hasPlainSecretsOverride = builtins.pathExists arrSecretsPlainOverride;
      arrSecretsPath =
        if hasAgeSecrets then
          config.age.secrets."arr-secrets".path
        else if hasPlainSecretsOverride then
          toString arrSecretsPlainOverride
        else
          toString arrSecretsPlainRepo;
      appDataRoot = "/mnt/ssd/appdata/docker/shelfmark";
      booksIngestRoot = "/mnt/ssd/scratch/imports/cwa";
      audiobookLibraryRoot = "/mnt/storage/data/media/audiobooks";
      torrentsRoot = "/mnt/ssd/scratch/downloads";
      cwaConfigRoot = "/mnt/ssd/appdata/docker/cwa/config";
      prowlarrConfigPath = "/mnt/ssd/appdata/docker/prowlarr/config.xml";
      shelfmarkEnvPath = "/run/shelfmark/shelfmark.env";
      pythonWithYaml = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
      shelfmarkEntrypoint = pkgs.writeTextFile {
        name = "shelfmark-entrypoint";
        executable = true;
        text = ''
          #!/bin/bash
          set -euo pipefail

          /app/.venv/bin/python <<'PY'
          from pathlib import Path

          source_path = Path("/app/shelfmark/release_sources/prowlarr/source.py")
          source = source_path.read_text(encoding="utf-8")
          indent = " " * 20
          continuation = " " * 24
          original = "\n".join([
              f"{indent}indexer_query = (",
              f"{continuation}enriched_query",
              f"{continuation}if indexer_id in enriched_indexer_ids_set and enriched_query",
              f"{continuation}else query",
              f"{indent})",
          ])
          patched = "\n".join([
              f"{indent}use_enriched_query = (",
              f"{continuation}content_type != \"audiobook\"",
              f"{continuation}and indexer_id in enriched_indexer_ids_set",
              f"{continuation}and enriched_query",
              f"{indent})",
              f"{indent}indexer_query = enriched_query if use_enriched_query else query",
          ])

          if original in source:
              source_path.write_text(source.replace(original, patched, 1), encoding="utf-8")
              print("[dotfiles] Patched Shelfmark Prowlarr audiobook queries")
          elif patched in source:
              print("[dotfiles] Shelfmark Prowlarr audiobook query patch already applied")
          else:
              raise SystemExit("Shelfmark Prowlarr source patch context not found")
          PY

          exec /app/entrypoint.sh "$@"
        '';
      };
    in
    {
      systemd.tmpfiles.rules = [
        "d ${appDataRoot} 0775 99 100 -"
        "d /run/shelfmark 0755 root root -"
      ];

      systemd.services.shelfmark-env = {
        description = "Generate Shelfmark runtime environment";
        requires = [
          "mnt-ssd.mount"
          "mnt-storage.mount"
        ];
        after = [
          "mnt-ssd.mount"
          "mnt-storage.mount"
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = with pkgs; [
          bash
          coreutils
        ];
        script = ''
                    set -euo pipefail

                    mkdir -p /run/shelfmark
                    tmp_env="$(mktemp /run/shelfmark/shelfmark.env.XXXXXX)"

                    printf '%s\n' \
                      'QBITTORRENT_URL=http://192.168.0.50:8081' \
                      'QBITTORRENT_CATEGORY=books' \
                      'QBITTORRENT_CATEGORY_AUDIOBOOK=audiobook' \
                      'QBITTORRENT_DOWNLOAD_DIR=/downloads' \
                      'PROWLARR_TORRENT_CLIENT=qbittorrent' \
                      > "$tmp_env"

                    if [ -r "${arrSecretsPath}" ]; then
                      ${pythonWithYaml}/bin/python3 - "${arrSecretsPath}" >> "$tmp_env" <<'PY'
          import pathlib
          import sys
          import yaml

          secrets_path = pathlib.Path(sys.argv[1])
          data = yaml.safe_load(secrets_path.read_text(encoding="utf-8")) or {}

          mapping = {
              "QBITTORRENT_USER": "QBITTORRENT_USERNAME",
              "QBITTORRENT_PASS": "QBITTORRENT_PASSWORD",
          }

          for source_key, env_key in mapping.items():
              value = data.get(source_key)
              if value:
                  print(f"{env_key}={value}")
          PY
                    fi

                    if [ -r "${prowlarrConfigPath}" ]; then
                      ${pkgs.python3}/bin/python3 - "${prowlarrConfigPath}" >> "$tmp_env" <<'PY'
          import pathlib
          import sys
          import xml.etree.ElementTree as ET

          config_path = pathlib.Path(sys.argv[1])
          api_key = (ET.parse(config_path).getroot().findtext("ApiKey") or "").strip()

          if api_key:
              print("PROWLARR_ENABLED=true")
              print("PROWLARR_URL=http://192.168.0.50:9696")
              print(f"PROWLARR_API_KEY={api_key}")
          PY
                    fi

                    chmod 0400 "$tmp_env"
                    mv "$tmp_env" "${shelfmarkEnvPath}"
        '';
      };

      virtualisation.oci-containers.containers.shelfmark = {
        image = "ghcr.io/calibrain/shelfmark:latest";
        environment = {
          PUID = "99";
          PGID = "100";
          TZ = "America/Toronto";
          SEARCH_MODE = "universal";
          AUTH_METHOD = "cwa";
          CWA_DB_PATH = "/auth/app.db";
          CALIBRE_WEB_URL = "http://192.168.0.50:8083";
          INGEST_DIR = "/books";
          DESTINATION_AUDIOBOOK = "/audiobooks";
          FILE_ORGANIZATION = "organize";
          FILE_ORGANIZATION_AUDIOBOOK = "organize";
          HARDLINK_TORRENTS = "false";
          HARDLINK_TORRENTS_AUDIOBOOK = "false";
        };
        environmentFiles = [ shelfmarkEnvPath ];
        volumes = [
          "${appDataRoot}:/config"
          "${booksIngestRoot}:/books"
          "${audiobookLibraryRoot}:/audiobooks"
          "${torrentsRoot}:/downloads"
          "${cwaConfigRoot}:/auth:ro"
          "${shelfmarkEntrypoint}:/app/dotfiles-shelfmark-entrypoint:ro"
        ];
        cmd = [ "/app/dotfiles-shelfmark-entrypoint" ];
        ports = [ "8084:8084" ];
        extraOptions = [ "--label=com.centurylinklabs.watchtower.enable=true" ];
      };

      systemd.services.docker-shelfmark = {
        requires = [
          "mnt-ssd.mount"
          "mnt-storage.mount"
          "shelfmark-env.service"
        ];
        after = [
          "mnt-ssd.mount"
          "mnt-storage.mount"
          "shelfmark-env.service"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 8084 ];
    };
}
