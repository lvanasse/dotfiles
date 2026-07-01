{ ... }:
{
  flake.modules.nixos."services.mousehole" =
    { pkgs, ... }:
    let
      appDataRoot = "/mnt/ssd/appdata/docker/mousehole";
      prowlarrConfigPath = "/mnt/ssd/appdata/docker/prowlarr/config.xml";
      syncProwlarrMam = pkgs.writeShellApplication {
        name = "mousehole-sync-prowlarr-mam";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.curl
          pkgs.gnused
          pkgs.jq
          pkgs.systemd
        ];
        text = ''
          set -euo pipefail

          state_path="${appDataRoot}/state.json"
          prowlarr_config="${prowlarrConfigPath}"
          prowlarr_api="http://127.0.0.1:9696/api/v1"

          if ! systemctl --quiet is-active docker-prowlarr.service; then
            echo "Prowlarr is not running; skipping"
            exit 0
          fi

          if [ ! -s "$state_path" ] || [ ! -s "$prowlarr_config" ]; then
            echo "Mousehole or Prowlarr runtime config is missing; skipping"
            exit 0
          fi

          mam_cookie="$(jq -r '.currentCookie // .cookie // empty' "$state_path")"
          if [ -z "$mam_cookie" ]; then
            echo "Mousehole has no current MAM cookie yet; skipping"
            exit 0
          fi

          api_key="$(sed -n 's:.*<ApiKey>\(.*\)</ApiKey>.*:\1:p' "$prowlarr_config")"
          if [ -z "$api_key" ]; then
            echo "Prowlarr API key not found; skipping"
            exit 0
          fi

          workdir="$(mktemp -d)"
          trap 'rm -rf "$workdir"' EXIT

          curl -fsS -H "X-Api-Key: $api_key" "$prowlarr_api/indexer" > "$workdir/indexers.json"
          indexer_id="$(
            jq -r '
              .[]
              | select(.implementation == "MyAnonamouse" or .name == "MyAnonamouse")
              | .id
            ' "$workdir/indexers.json" | head -n1
          )"

          if [ -z "$indexer_id" ]; then
            echo "Prowlarr MyAnonamouse indexer not found; skipping"
            exit 0
          fi

          curl -fsS -H "X-Api-Key: $api_key" "$prowlarr_api/indexer/$indexer_id" > "$workdir/indexer.json"
          current_mam="$(
            jq -r '.fields[] | select(.name == "mamId") | .value // empty' "$workdir/indexer.json"
          )"

          if [ "$current_mam" = "$mam_cookie" ]; then
            echo "Prowlarr MyAnonamouse credential already matches Mousehole"
            exit 0
          fi

          jq --arg mam "$mam_cookie" '
            .fields |= map(if .name == "mamId" then .value = $mam else . end)
          ' "$workdir/indexer.json" > "$workdir/indexer-updated.json"

          update_code="$(
            curl -sS -o "$workdir/update-response.json" -w '%{http_code}' \
              -X PUT \
              -H "X-Api-Key: $api_key" \
              -H "Content-Type: application/json" \
              --data-binary "@$workdir/indexer-updated.json" \
              "$prowlarr_api/indexer/$indexer_id"
          )"

          if [ "$update_code" != "200" ] && [ "$update_code" != "202" ]; then
            echo "Prowlarr MyAnonamouse update failed with HTTP $update_code"
            exit 1
          fi

          test_code="$(
            curl -sS -o "$workdir/test-response.json" -w '%{http_code}' \
              -X POST \
              -H "X-Api-Key: $api_key" \
              -H "Content-Type: application/json" \
              --data-binary "@$workdir/indexer-updated.json" \
              "$prowlarr_api/indexer/test"
          )"

          if [ "$test_code" != "200" ]; then
            echo "Prowlarr MyAnonamouse test failed with HTTP $test_code"
            exit 1
          fi

          echo "Prowlarr MyAnonamouse credential synced from Mousehole"
        '';
      };
    in
    {
      systemd.tmpfiles.rules = [
        "d ${appDataRoot} 0755 root root -"
      ];

      virtualisation.oci-containers.containers.mousehole = {
        image = "tmmrtn/mousehole:latest";
        environment = {
          TZ = "America/Toronto";
          MOUSEHOLE_PORT = "5010";
          MOUSEHOLE_STATE_DIR_PATH = "/srv/mousehole";
          # Mousehole v0.4.0 requires an explicit auth choice. This preserves
          # the previous unauthenticated behavior for the private server UI.
          MOUSEHOLE_INSECURE_ALLOW_NO_AUTH = "true";
          MOUSEHOLE_ALLOWED_HOSTS = "localhost,127.0.0.1,[::1],server,192.168.0.50,100.113.124.8,server.tail7e8d6c.ts.net";
        };
        volumes = [
          "${appDataRoot}:/srv/mousehole"
        ];
        ports = [ "5010:5010" ];
        extraOptions = [ "--label=com.centurylinklabs.watchtower.enable=true" ];
      };

      systemd.services.docker-mousehole = {
        requires = [
          "docker.service"
          "mnt-ssd.mount"
        ];
        after = [
          "docker.service"
          "mnt-ssd.mount"
        ];
      };

      systemd.services.mousehole-sync-prowlarr-mam = {
        description = "Sync Prowlarr MyAnonamouse credential from Mousehole";
        after = [
          "docker-mousehole.service"
          "docker-prowlarr.service"
          "mnt-ssd.mount"
        ];
        requires = [ "mnt-ssd.mount" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${syncProwlarrMam}/bin/mousehole-sync-prowlarr-mam";
        };
      };

      systemd.timers.mousehole-sync-prowlarr-mam = {
        description = "Periodically sync Prowlarr MyAnonamouse credential from Mousehole";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = "5min";
          Unit = "mousehole-sync-prowlarr-mam.service";
        };
      };

      networking.firewall.allowedTCPPorts = [ 5010 ];
    };
}
