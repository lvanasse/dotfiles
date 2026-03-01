{ ... }:
{
  flake.modules.nixos."services.portainer" =
    { ... }:
    {
      virtualisation.oci-containers.containers.portainer = {
        image = "portainer/portainer-ce:latest";
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "/mnt/data3/appdata/portainer:/data"
        ];
        ports = [ "9000:9000" ];
        extraOptions = [
          "--label=com.centurylinklabs.watchtower.enable=true"
        ];
      };

      systemd.services.docker-portainer = {
        requires = [ "docker.service" "mnt-data3.mount" ];
        after = [ "docker.service" "mnt-data3.mount" ];
      };

      networking.firewall.allowedTCPPorts = [ 9000 ];
    };
}
