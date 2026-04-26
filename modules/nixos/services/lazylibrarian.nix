{ ... }:
{
  flake.modules.nixos."services.lazylibrarian" =
    { ... }:
    let
      appDataRoot = "/mnt/data3/appdata/lazylibrarian";
      downloadsRoot = "/mnt/storage/data/books/downloads";
      ingestRoot = "/mnt/storage/data/books/ingest";
      booksRoot = "/mnt/storage/data/books/library";
    in
    {
      systemd.tmpfiles.rules = [
        "d ${appDataRoot} 0775 99 100 -"
        "d ${downloadsRoot} 0775 99 100 -"
        "d ${ingestRoot} 0775 99 100 -"
        "d ${booksRoot} 0775 99 100 -"
      ];

      virtualisation.oci-containers.containers.lazylibrarian = {
        image = "lscr.io/linuxserver/lazylibrarian:latest";
        environment = {
          PUID = "99";
          PGID = "100";
          TZ = "America/Toronto";
          UMASK = "002";
        };
        volumes = [
          "${appDataRoot}:/config"
          "${downloadsRoot}:/downloads"
          "${downloadsRoot}:/books-downloads"
          "${ingestRoot}:/ingest"
          "${booksRoot}:/books"
        ];
        ports = [ "5299:5299" ];
        extraOptions = [ "--label=com.centurylinklabs.watchtower.enable=true" ];
      };

      systemd.services.docker-lazylibrarian = {
        requires = [
          "mnt-data3.mount"
          "mnt-storage.mount"
        ];
        after = [
          "mnt-data3.mount"
          "mnt-storage.mount"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 5299 ];
    };
}
