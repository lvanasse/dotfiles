{ inputs, ... }:
let
  linkwardenEnvAge = "${inputs.secrets}/server/linkwarden.env.age";
in
{
  flake.modules.nixos."services.linkwarden" =
    { config, lib, pkgs, ... }:
    let
      hasLinkwardenEnv = builtins.pathExists linkwardenEnvAge;
      appDataRoot = "/mnt/data3/appdata/linkwarden";
      defaultNextAuthSecret = builtins.hashString "sha256" "linkwarden-nextauth-secret";
      defaultMeiliKey = builtins.hashString "sha256" "linkwarden-meili-key";
    in
    {
      systemd.services.docker-network-linkwarden = {
        description = "Create docker network for Linkwarden";
        wantedBy = [ "docker.service" ];
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          if ! ${pkgs.docker}/bin/docker network inspect linkwarden >/dev/null 2>&1; then
            ${pkgs.docker}/bin/docker network create linkwarden >/dev/null
          fi
        '';
      };

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
        volumes = [ "${appDataRoot}/postgres:/var/lib/postgresql/data" ];
        extraOptions = [
          "--network=linkwarden"
          "--network-alias=linkwarden-postgres"
          "--label=com.centurylinklabs.watchtower.enable=true"
        ];
      };

      virtualisation.oci-containers.containers.linkwarden-meilisearch = {
        image = "getmeili/meilisearch:v1.12.8";
        environment = lib.optionalAttrs (!hasLinkwardenEnv) {
          MEILI_MASTER_KEY = defaultMeiliKey;
        };
        environmentFiles = lib.optional hasLinkwardenEnv config.age.secrets."linkwarden-env".path;
        volumes = [ "${appDataRoot}/meili:/meili_data" ];
        extraOptions = [
          "--network=linkwarden"
          "--network-alias=linkwarden-meilisearch"
          "--label=com.centurylinklabs.watchtower.enable=true"
        ];
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
            NEXTAUTH_URL = "https://linkwarden.ludovicvanasse.com/api/v1/auth";
          }
          // lib.optionalAttrs (!hasLinkwardenEnv) {
            DATABASE_URL = "postgresql://postgres@linkwarden-postgres:5432/postgres";
            NEXTAUTH_SECRET = defaultNextAuthSecret;
            MEILI_MASTER_KEY = defaultMeiliKey;
          };
        environmentFiles = lib.optional hasLinkwardenEnv config.age.secrets."linkwarden-env".path;
        volumes = [ "${appDataRoot}/data:/data/data" ];
        ports = [ "3000:3000" ];
        extraOptions = [
          "--network=linkwarden"
          "--label=com.centurylinklabs.watchtower.enable=true"
        ];
      };

      systemd.services = {
        docker-linkwarden-postgres = {
          requires = [
            "docker-network-linkwarden.service"
            "mnt-data3.mount"
          ];
          after = [
            "docker-network-linkwarden.service"
            "mnt-data3.mount"
          ];
        };
        docker-linkwarden-meilisearch = {
          requires = [
            "docker-network-linkwarden.service"
            "mnt-data3.mount"
          ];
          after = [
            "docker-network-linkwarden.service"
            "mnt-data3.mount"
          ];
        };
        docker-linkwarden = {
          requires = [
            "docker-network-linkwarden.service"
            "mnt-data3.mount"
          ];
          after = [
            "docker-network-linkwarden.service"
            "mnt-data3.mount"
          ];
        };
      };

      networking.firewall.allowedTCPPorts = [ 3000 ];
    };
}
