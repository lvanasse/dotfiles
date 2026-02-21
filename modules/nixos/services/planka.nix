{ inputs, ... }:
let
  plankaEnvAge = "${inputs.secrets}/server/planka.env.age";
in
{
  flake.modules.nixos."services.planka" =
    { config, lib, ... }:
    let
      hasPlankaEnv = builtins.pathExists plankaEnvAge;
    in
    {
      age.secrets = lib.mkIf hasPlankaEnv {
        "planka-env" = {
          file = plankaEnvAge;
          path = "/run/agenix/planka-env";
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };

      virtualisation.oci-containers.containers.planka-postgres = {
        image = "postgres:16-alpine";
        environment = {
          POSTGRES_DB = "planka";
          POSTGRES_HOST_AUTH_METHOD = "trust";
        };
        volumes = [ "/mnt/storage/appdata/planka/postgres:/var/lib/postgresql/data" ];
      };

      virtualisation.oci-containers.containers.planka = {
        image = "ghcr.io/plankanban/planka:latest";
        dependsOn = [ "planka-postgres" ];
        environment =
          {
            BASE_URL = "http://192.168.0.50:1337";
          }
          // lib.optionalAttrs (!hasPlankaEnv) {
            DATABASE_URL = "postgresql://postgres@planka-postgres/planka";
            SECRET_KEY = "replace-me";
          };
        environmentFiles = lib.optional hasPlankaEnv config.age.secrets."planka-env".path;
        volumes = [ "/mnt/storage/appdata/planka/data:/app/data" ];
        ports = [ "1337:1337" ];
      };

      networking.firewall.allowedTCPPorts = [ 1337 ];
    };
}
