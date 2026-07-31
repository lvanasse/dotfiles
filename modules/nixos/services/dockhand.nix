{ ... }:
{
  flake.modules.nixos."services.dockhand" =
    { lib, pkgs, ... }:
    {
      systemd.tmpfiles.rules = [
        "d /mnt/ssd/appdata/docker/dockhand 0755 root root -"
      ];

      virtualisation.oci-containers.containers.dockhand = {
        image = "fnsys/dockhand:latest";
        environment = {
          DATA_DIR = "/mnt/ssd/appdata/docker/dockhand";
          DOCKER_HOST = "unix:///var/run/docker.sock";
        };
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "/mnt/ssd/appdata/docker/dockhand:/mnt/ssd/appdata/docker/dockhand"
        ];
        ports = [ "3001:3000" ];
        extraOptions = [ "--user=0:0" ];
      };

      systemd.services.docker-dockhand = {
        preStart = lib.mkAfter ''
          db=/mnt/ssd/appdata/docker/dockhand/db/dockhand.db
          if [ -f "$db" ]; then
            ${pkgs.sqlite}/bin/sqlite3 "$db" \
              "UPDATE auto_update_settings SET enabled = 0 WHERE enabled != 0;" \
              || true
          fi
        '';
        requires = [
          "docker.service"
          "mnt-ssd.mount"
        ];
        after = [
          "docker.service"
          "mnt-ssd.mount"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 3001 ];
    };
}
