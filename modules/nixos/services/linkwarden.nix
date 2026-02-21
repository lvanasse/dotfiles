{ inputs, ... }:
let
  linkwardenEnvAge = "${inputs.secrets}/server/linkwarden.env.age";
in
{
  flake.modules.nixos."services.linkwarden" =
    { config, lib, ... }:
    let
      hasLinkwardenEnv = builtins.pathExists linkwardenEnvAge;
    in
    {
      age.secrets = lib.mkIf hasLinkwardenEnv {
        "linkwarden-env" = {
          file = linkwardenEnvAge;
          path = "/run/agenix/linkwarden-env";
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };

      virtualisation.oci-containers.containers.linkwarden-postgres = {
        image = "postgres:16-alpine";
        environment = {
          POSTGRES_HOST_AUTH_METHOD = "trust";
        };
        environmentFiles = lib.optional hasLinkwardenEnv config.age.secrets."linkwarden-env".path;
        volumes = [ "/mnt/storage/appdata/linkwarden/postgres:/var/lib/postgresql/data" ];
      };

      virtualisation.oci-containers.containers.linkwarden-meilisearch = {
        image = "getmeili/meilisearch:v1.12.8";
        environment = lib.optionalAttrs (!hasLinkwardenEnv) {
          MEILI_MASTER_KEY = "replace-me";
        };
        environmentFiles = lib.optional hasLinkwardenEnv config.age.secrets."linkwarden-env".path;
        volumes = [ "/mnt/storage/appdata/linkwarden/meili:/meili_data" ];
      };

      virtualisation.oci-containers.containers.linkwarden = {
        image = "ghcr.io/linkwarden/linkwarden:latest";
        dependsOn = [
          "linkwarden-postgres"
          "linkwarden-meilisearch"
        ];
        environment =
          {
            MEILI_HOST = "http://linkwarden-meilisearch:7700";
          }
          // lib.optionalAttrs (!hasLinkwardenEnv) {
            DATABASE_URL = "postgresql://postgres@linkwarden-postgres:5432/postgres";
            NEXTAUTH_URL = "http://192.168.0.50:3000/api/v1/auth";
            NEXTAUTH_SECRET = "replace-me";
            MEILI_MASTER_KEY = "replace-me";
          };
        environmentFiles = lib.optional hasLinkwardenEnv config.age.secrets."linkwarden-env".path;
        volumes = [ "/mnt/storage/appdata/linkwarden/data:/data/data" ];
        ports = [ "3000:3000" ];
      };

      networking.firewall.allowedTCPPorts = [ 3000 ];
    };
}
