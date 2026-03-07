{ ... }:
{
  flake.modules.nixos."services.actual" =
    { ... }:
    {
      virtualisation.oci-containers.containers.actual = {
        image = "actualbudget/actual-server:latest";
        volumes = [ "/mnt/data3/appdata/actual:/data" ];
        ports = [ "5006:5006" ];
      };

      # Ensure appdata mount exists before container startup.
      systemd.services.docker-actual = {
        requires = [ "mnt-data3.mount" ];
        after = [ "mnt-data3.mount" ];
      };

      networking.firewall.allowedTCPPorts = [ 5006 ];
    };
}
