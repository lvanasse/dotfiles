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

          googlebooks_path = Path("/app/shelfmark/metadata_providers/googlebooks.py")
          googlebooks_source = googlebooks_path.read_text(encoding="utf-8")
          googlebooks_replacements = [
              (
                  "from contextlib import suppress\n",
                  "from contextlib import suppress\nimport os\nimport time\n",
              ),
              (
                  "_HTTP_STATUS_NOT_FOUND = HTTPStatus.NOT_FOUND\n",
                  "_HTTP_STATUS_NOT_FOUND = HTTPStatus.NOT_FOUND\n"
                  "_HTTP_STATUS_TOO_MANY_REQUESTS = HTTPStatus.TOO_MANY_REQUESTS\n"
                  "_GOOGLEBOOKS_QUOTA_BACKOFF_UNTIL = 0.0\n",
              ),
              (
                  "        # Build request params\n"
                  "        params: dict[str, Any] = {\n"
                  "            \"q\": query,\n"
                  "            \"maxResults\": min(options.limit, 40),  # Google max is 40\n",
                  "        with suppress(TypeError, ValueError):\n"
                  "            max_results_cap = int(os.environ.get(\"GOOGLEBOOKS_MAX_RESULTS\", \"5\"))\n"
                  "        if \"max_results_cap\" not in locals():\n"
                  "            max_results_cap = 5\n"
                  "        max_results_cap = max(1, min(max_results_cap, 40))\n"
                  "\n"
                  "        # Build request params\n"
                  "        params: dict[str, Any] = {\n"
                  "            \"q\": query,\n"
                  "            \"maxResults\": min(options.limit, max_results_cap, 40),  # Google max is 40\n",
              ),
              (
                  "        # Add API key to params\n"
                  "        params[\"key\"] = self.api_key\n",
                  "        global _GOOGLEBOOKS_QUOTA_BACKOFF_UNTIL\n"
                  "        if time.time() < _GOOGLEBOOKS_QUOTA_BACKOFF_UNTIL:\n"
                  "            logger.warning(\"Google Books API quota backoff active; skipping request\")\n"
                  "            return None\n"
                  "\n"
                  "        # Add API key to params\n"
                  "        params[\"key\"] = self.api_key\n",
              ),
              (
                  "                if e.response.status_code == _HTTP_STATUS_FORBIDDEN:\n"
                  "                    # Quota exceeded or invalid API key\n"
                  "                    logger.exception(\n"
                  "                        \"Google Books API: quota exceeded or invalid API key (HTTP 403)\"\n"
                  "                    )\n",
                  "                if e.response.status_code in {_HTTP_STATUS_FORBIDDEN, _HTTP_STATUS_TOO_MANY_REQUESTS}:\n"
                  "                    with suppress(TypeError, ValueError):\n"
                  "                        backoff_seconds = int(os.environ.get(\"GOOGLEBOOKS_QUOTA_BACKOFF_SECONDS\", \"21600\"))\n"
                  "                    if \"backoff_seconds\" not in locals():\n"
                  "                        backoff_seconds = 21600\n"
                  "                    backoff_seconds = max(60, backoff_seconds)\n"
                  "                    _GOOGLEBOOKS_QUOTA_BACKOFF_UNTIL = time.time() + backoff_seconds\n"
                  "                    logger.warning(\n"
                  "                        \"Google Books API quota or rate limit hit (HTTP %s); backing off for %s seconds\",\n"
                  "                        e.response.status_code,\n"
                  "                        backoff_seconds,\n"
                  "                    )\n",
              ),
          ]
          googlebooks_patched = googlebooks_source
          for before, after in googlebooks_replacements:
              if after in googlebooks_patched:
                  continue
              if before not in googlebooks_patched:
                  raise SystemExit("Shelfmark Google Books patch context not found")
              googlebooks_patched = googlebooks_patched.replace(before, after, 1)

          if googlebooks_patched != googlebooks_source:
              googlebooks_path.write_text(googlebooks_patched, encoding="utf-8")
              print("[dotfiles] Patched Shelfmark Google Books request limits")
          else:
              print("[dotfiles] Shelfmark Google Books request patch already applied")
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
          GOOGLEBOOKS_MAX_RESULTS = "5";
          GOOGLEBOOKS_QUOTA_BACKOFF_SECONDS = "21600";
          AUTH_METHOD = "cwa";
          CWA_DB_PATH = "/auth/app.db";
          CALIBRE_WEB_URL = "http://192.168.0.50:8083";
          INGEST_DIR = "/books";
          DESTINATION_AUDIOBOOK = "/audiobooks";
          FILE_ORGANIZATION = "organize";
          FILE_ORGANIZATION_AUDIOBOOK = "rename";
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
