{ inputs, ... }:
let
  mariadbEnvAge = "${inputs.secrets}/server/mariadb.env.age";
in
{
  flake.modules.nixos."services.mariadb" =
    { config, lib, ... }:
    let
      hasMariaDbEnv = builtins.pathExists mariadbEnvAge;
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
        environment =
          {
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
          "/mnt/storage/appdata/mariadb:/config"
        ];
        ports = [ "3306:3306" ];
      };

      networking.firewall.allowedTCPPorts = [ 3306 ];
    };
}
