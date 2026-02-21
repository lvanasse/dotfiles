{ ... }:
{
  flake.modules.nixos."services.nextcloud" =
    { ... }:
    {
      virtualisation.oci-containers.containers.nextcloud = {
        image = "lscr.io/linuxserver/nextcloud:latest";
        environment = {
          PUID = "1000";
          PGID = "1000";
          UMASK = "022";
        };
        volumes = [
          "/var/lib/nextcloud:/config"
          "/mnt/storage/nextcloud:/data"
        ];
        ports = [ "444:443" ];
      };

      networking.firewall.allowedTCPPorts = [ 444 ];
    };
}
