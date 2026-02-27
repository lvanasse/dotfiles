{ ... }:
{
  flake.modules.nixos."services.actual" =
    { ... }:
    {
      virtualisation.oci-containers.containers.actual = {
        image = "actualbudget/actual-server:latest";
        volumes = [ "/mnt/storage/appdata/actual:/data" ];
        ports = [ "5006:5006" ];
      };

      networking.firewall.allowedTCPPorts = [ 5006 ];
    };
}
