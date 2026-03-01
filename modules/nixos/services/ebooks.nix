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
          "/mnt/data3/appdata/calibre-web-automated/config:/config"
          "/mnt/storage/data/books/ingest:/cwa-book-ingest"
          "/mnt/storage/data/books/library:/calibre-library"
          "/mnt/data3/appdata/calibre-web-automated/plugins:/config/.config/calibre/plugins"
        ];
        ports = [ "8083:8083" ];
        extraOptions = [ "--label=com.centurylinklabs.watchtower.enable=true" ];
      };

      systemd.services.docker-calibre-web-automated = {
        requires = [
          "mnt-data3.mount"
          "mnt-storage.mount"
        ];
        after = [
          "mnt-data3.mount"
          "mnt-storage.mount"
        ];
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
          TimeoutStartSec = "15s";
        };
        path = with pkgs; [
          bash
          coreutils
          sqlite
        ];
        script = ''
          set -euo pipefail

          db="/mnt/data3/appdata/calibre-web-automated/config/app.db"

          if [ ! -f "$db" ]; then
            echo "[cwa-kosync-enable] app.db not found at $db; skipping"
            exit 0
          fi

          if ! sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table' AND name='cwa_settings';" \
            | grep -q cwa_settings; then
            echo "[cwa-kosync-enable] cwa_settings table not ready yet; skipping"
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
