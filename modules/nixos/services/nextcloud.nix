{ ... }:
{
  flake.modules.nixos."services.nextcloud" =
    { pkgs, ... }:
    {
      virtualisation.oci-containers.containers.nextcloud = {
        image = "lscr.io/linuxserver/nextcloud";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
        volumes = [
          "/mnt/data3/appdata/nextcloud:/config"
          "/mnt/storage/nextcloud:/data"
        ];
        ports = [ "444:443" ];
      };

      systemd.services.docker-nextcloud = {
        requires = [
          "mnt-data3.mount"
          "mnt-storage.mount"
        ];
        after = [
          "mnt-data3.mount"
          "mnt-storage.mount"
        ];
      };

      systemd.services.nextcloud-configure = {
        description = "Apply Nextcloud public URL settings";
        after = [ "docker-nextcloud.service" ];
        wants = [ "docker-nextcloud.service" ];
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "120s";
        };
        path = with pkgs; [
          bash
          coreutils
          docker_29
          gnugrep
        ];
        script = ''
          set -u
          set -o pipefail

          if ! docker ps --format '{{.Names}}' | grep -q '^nextcloud$'; then
            echo "[nextcloud-configure] nextcloud container not running; skipping"
            exit 0
          fi

          ready=0
          deadline=$(( $(date +%s) + 90 ))
          while [ "$(date +%s)" -lt "$deadline" ]; do
            if timeout 10s docker exec -i nextcloud php /app/www/public/occ status >/dev/null 2>&1; then
              ready=1
              break
            fi
            sleep 5
          done

          if [ "$ready" -ne 1 ]; then
            echo "[nextcloud-configure] occ not ready after waiting; skipping"
            exit 0
          fi

          occ() {
            timeout 15s docker exec -i nextcloud php /app/www/public/occ "$@" || true
          }

          occ config:system:set overwrite.cli.url --value="https://nextcloud.ludovicvanasse.com"
          occ config:system:set overwriteprotocol --value="https"
          occ config:system:set overwritehost --value="nextcloud.ludovicvanasse.com"
          occ config:system:set trusted_domains 0 --value="192.168.0.50:444"
          occ config:system:set trusted_domains 1 --value="nextcloud.ludovicvanasse.com"
          occ config:system:set trusted_proxies 0 --value="172.17.0.0/16"
        '';
      };

      systemd.timers.nextcloud-configure = {
        description = "Run Nextcloud public URL configuration";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2min";
          Unit = "nextcloud-configure.service";
        };
      };

      networking.firewall.allowedTCPPorts = [ 444 ];
    };
}
