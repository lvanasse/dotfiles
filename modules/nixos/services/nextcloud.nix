{ ... }:
{
  flake.modules.nixos."services.nextcloud" =
    { ... }:
    {
      virtualisation.oci-containers.containers.nextcloud = {
        image = "lscr.io/linuxserver/nextcloud";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
        volumes = [
          "/mnt/storage/appdata/nextcloud:/config"
          "/mnt/storage/nextcloud:/data"
        ];
        ports = [ "444:443" ];
      };

      networking.firewall.allowedTCPPorts = [ 444 ];
    };
}
