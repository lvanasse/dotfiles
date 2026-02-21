{ ... }:
{
  flake.modules.nixos."services.ebooks" =
    { pkgs, ... }:
    {
      # Calibre-Web Automated as a BookFusion replacement
      virtualisation.oci-containers.containers.calibre-web-automated = {
        image = "crocodilestick/calibre-web-automated:latest";
        environment = {
          PUID = "99";
          PGID = "100";
          TZ = "America/Toronto";
          NETWORK_SHARE_MODE = "true";
        };
        volumes = [
          "/mnt/storage/appdata/calibre-web-automated/config:/config"
          "/mnt/storage/data/books/ingest:/cwa-book-ingest"
          "/mnt/storage/data/books/library:/calibre-library"
          "/mnt/storage/appdata/calibre-web-automated/plugins:/config/.config/calibre/plugins"
        ];
        ports = [ "8083:8083" ];
      };

      networking.firewall.allowedTCPPorts = [ 8083 ];

      # CWA currently stores KOReader/KOSync enablement in app.db, not env vars.
      # This ensures /kosync endpoints are enabled declaratively after startup.
      systemd.services.cwa-kosync-enable = {
        description = "Enable KOReader/KOSync in Calibre-Web-Automated";
        wantedBy = [ "multi-user.target" ];
        after = [ "docker-calibre-web-automated.service" ];
        wants = [ "docker-calibre-web-automated.service" ];
        serviceConfig = {
          Type = "oneshot";
        };
        path = with pkgs; [
          bash
          coreutils
          sqlite
        ];
        script = ''
          set -euo pipefail

          db="/mnt/storage/appdata/calibre-web-automated/config/app.db"

          # Wait briefly for first-run initialization to create app.db
          for _ in $(seq 1 90); do
            if [ -f "$db" ]; then
              break
            fi
            sleep 2
          done

          if [ ! -f "$db" ]; then
            echo "[cwa-kosync-enable] app.db not found at $db; skipping"
            exit 0
          fi

          # Ensure a settings row exists, then enable KOReader sync.
          sqlite3 "$db" "
            INSERT INTO cwa_settings (koreader_sync_enabled)
            SELECT 1
            WHERE NOT EXISTS (SELECT 1 FROM cwa_settings);
            UPDATE cwa_settings SET koreader_sync_enabled = 1;
          "

          echo "[cwa-kosync-enable] KOReader/KOSync enabled"
        '';
      };
    };
}
