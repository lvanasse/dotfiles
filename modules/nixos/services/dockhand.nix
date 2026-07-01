{ ... }:
{
  flake.modules.nixos."services.dockhand" =
    { ... }:
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
