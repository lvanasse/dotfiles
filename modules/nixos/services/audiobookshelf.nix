{ ... }:
{
  flake.modules.nixos."services.audiobookshelf" =
    { ... }:
    let
      appDataRoot = "/mnt/data3/appdata/audiobookshelf";
      audiobookLibraryRoot = "/mnt/storage/data/media/audiobooks";
    in
    {
      systemd.tmpfiles.rules = [
        "d ${appDataRoot} 0775 99 100 -"
        "d ${appDataRoot}/config 0775 99 100 -"
        "d ${appDataRoot}/metadata 0775 99 100 -"
        "d ${audiobookLibraryRoot} 0775 99 100 -"
        "z ${audiobookLibraryRoot} 0775 99 100 -"
      ];

      virtualisation.oci-containers.containers.audiobookshelf = {
        image = "ghcr.io/advplyr/audiobookshelf:latest";
        environment = {
          TZ = "America/Toronto";
        };
        volumes = [
          "${audiobookLibraryRoot}:/audiobooks"
          "${appDataRoot}/metadata:/metadata"
          "${appDataRoot}/config:/config"
        ];
        ports = [ "13378:80" ];
        extraOptions = [
          "--user=99:100"
          "--label=com.centurylinklabs.watchtower.enable=true"
        ];
      };

      systemd.services.docker-audiobookshelf = {
        requires = [
          "mnt-data3.mount"
          "mnt-storage.mount"
        ];
        after = [
          "mnt-data3.mount"
          "mnt-storage.mount"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 13378 ];
    };
}
