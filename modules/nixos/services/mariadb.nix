{ inputs, ... }:
let
  mariadbEnvAge = "${inputs.secrets}/server/mariadb.env.age";
in
{
  flake.modules.nixos."services.mariadb" =
    { config, lib, ... }:
    let
      hasMariaDbEnv = builtins.pathExists mariadbEnvAge;
      appDataRoot = "/mnt/ssd/appdata/docker/mariadb";
    in
    {
      age.secrets = lib.mkIf hasMariaDbEnv {
        "mariadb-env" = {
          file = mariadbEnvAge;
          path = "/run/agenix/mariadb-env";
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };

      virtualisation.oci-containers.containers.mariadb = {
        image = "lscr.io/linuxserver/mariadb";
        environment = {
          MYSQL_DATABASE = "nextcloud";
          MYSQL_USER = "nextcloud";
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        }
        // lib.optionalAttrs (!hasMariaDbEnv) {
          MYSQL_ROOT_PASSWORD = "replace-me";
          MYSQL_PASSWORD = "replace-me";
        };
        environmentFiles = lib.optional hasMariaDbEnv config.age.secrets."mariadb-env".path;
        volumes = [
          "${appDataRoot}:/config"
        ];
        ports = [ "3306:3306" ];
      };

      systemd.tmpfiles.rules = [
        "d ${appDataRoot} 0775 99 100 -"
      ];

      systemd.services.docker-mariadb = {
        requires = [ "mnt-ssd.mount" ];
        after = [ "mnt-ssd.mount" ];
      };

      networking.firewall.allowedTCPPorts = [ 3306 ];
    };
}
