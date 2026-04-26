{ ... }:
{
  flake.modules.nixos."services.readmeabook" =
    { ... }:
    let
      appDataRoot = "/mnt/data3/appdata/readmeabook";
      audiobookLibraryRoot = "/mnt/storage/data/media/audiobooks";
      downloadsRoot = "/mnt/storage/data/torrents";
    in
    {
      systemd.tmpfiles.rules = [
        "d ${appDataRoot} 0775 99 100 -"
        "d ${appDataRoot}/config 0775 99 100 -"
        "d ${appDataRoot}/cache 0775 99 100 -"
        "d ${appDataRoot}/pgdata 0775 103 100 -"
        "d ${appDataRoot}/redis 0775 99 100 -"
        "d ${audiobookLibraryRoot} 0775 99 100 -"
      ];

      virtualisation.oci-containers.containers.readmeabook = {
        image = "ghcr.io/kikootwo/readmeabook:latest";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "002";
          TZ = "America/Toronto";
        };
        volumes = [
          "${appDataRoot}/config:/app/config"
          "${appDataRoot}/cache:/app/cache"
          "${downloadsRoot}:/downloads"
          "${audiobookLibraryRoot}:/media"
          "${appDataRoot}/pgdata:/var/lib/postgresql/data"
          "${appDataRoot}/redis:/var/lib/redis"
        ];
        ports = [ "3030:3030" ];
        extraOptions = [ "--label=com.centurylinklabs.watchtower.enable=true" ];
      };

      systemd.services.docker-readmeabook = {
        requires = [
          "mnt-data3.mount"
          "mnt-storage.mount"
        ];
        after = [
          "mnt-data3.mount"
          "mnt-storage.mount"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 3030 ];
    };
}
