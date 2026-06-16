{ ... }:
{
  flake.modules.nixos."services.dockhand" =
    { ... }:
    {
      systemd.tmpfiles.rules = [
        "d /mnt/data3/appdata/dockhand 0755 root root -"
      ];

      virtualisation.oci-containers.containers.dockhand = {
        image = "fnsys/dockhand:latest";
        environment = {
          DATA_DIR = "/mnt/data3/appdata/dockhand";
          DOCKER_HOST = "unix:///var/run/docker.sock";
        };
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "/mnt/data3/appdata/dockhand:/mnt/data3/appdata/dockhand"
        ];
        ports = [ "3001:3000" ];
        extraOptions = [ "--user=0:0" ];
      };

      systemd.services.docker-dockhand = {
        requires = [
          "docker.service"
          "mnt-data3.mount"
        ];
        after = [
          "docker.service"
          "mnt-data3.mount"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 3001 ];
    };
}
