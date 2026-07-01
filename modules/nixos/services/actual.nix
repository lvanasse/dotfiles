{ ... }:
{
  flake.modules.nixos."services.actual" =
    { ... }:
    {
      virtualisation.oci-containers.containers.actual = {
        image = "actualbudget/actual-server:latest";
        volumes = [ "/mnt/ssd/appdata/docker/actual-budget:/data" ];
        ports = [ "5006:5006" ];
      };

      # Ensure appdata mount exists before container startup.
      systemd.services.docker-actual = {
        requires = [ "mnt-ssd.mount" ];
        after = [ "mnt-ssd.mount" ];
      };

      networking.firewall.allowedTCPPorts = [ 5006 ];
    };
}
