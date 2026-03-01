{ inputs, ... }:
let
  plankaEnvAge = "${inputs.secrets}/server/planka.env.age";
  plankaEnvPlainRepo = "${inputs.secrets}/server/planka.env";
  plankaEnvPlainOverride = ../../../overrides/planka.env;
in
{
  flake.modules.nixos."services.planka" =
    { config, lib, pkgs, ... }:
    let
      hasPlankaEnvAge = builtins.pathExists plankaEnvAge;
      hasPlankaEnvPlainRepo = builtins.pathExists plankaEnvPlainRepo;
      hasPlankaEnvPlainOverride = builtins.pathExists plankaEnvPlainOverride;
      hasPlankaEnv = hasPlankaEnvAge || hasPlankaEnvPlainRepo || hasPlankaEnvPlainOverride;
      plankaEnvPath =
        if hasPlankaEnvAge then
          config.age.secrets."planka-env".path
        else if hasPlankaEnvPlainOverride then
          toString plankaEnvPlainOverride
        else
          toString plankaEnvPlainRepo;
      appDataRoot = "/mnt/data3/appdata/planka";
      defaultSecret = builtins.hashString "sha256" "planka-secret";
    in
    {
      systemd.services.docker-network-planka = {
        description = "Create docker network for Planka";
        wantedBy = [ "docker.service" ];
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          if ! ${pkgs.docker}/bin/docker network inspect planka >/dev/null 2>&1; then
            ${pkgs.docker}/bin/docker network create planka >/dev/null
          fi
        '';
      };

      age.secrets = lib.mkIf hasPlankaEnvAge {
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
        volumes = [ "${appDataRoot}/postgres:/var/lib/postgresql/data" ];
        extraOptions = [
          "--network=planka"
          "--network-alias=planka-postgres"
          "--label=com.centurylinklabs.watchtower.enable=true"
        ];
      };

      virtualisation.oci-containers.containers.planka = {
        image = "ghcr.io/plankanban/planka:latest";
        dependsOn = [ "planka-postgres" ];
        environment =
          {
            BASE_URL = "https://planka.ludovicvanasse.com";
          }
          // lib.optionalAttrs (!hasPlankaEnv) {
            DATABASE_URL = "postgresql://postgres@planka-postgres/planka";
            SECRET_KEY = defaultSecret;
          };
        environmentFiles = lib.optional hasPlankaEnv plankaEnvPath;
        volumes = [ "${appDataRoot}/data:/app/data" ];
        ports = [ "1337:1337" ];
        extraOptions = [
          "--network=planka"
          "--label=com.centurylinklabs.watchtower.enable=true"
        ];
      };

      systemd.services = {
        docker-planka-postgres = {
          requires = [
            "docker-network-planka.service"
            "mnt-data3.mount"
          ];
          after = [
            "docker-network-planka.service"
            "mnt-data3.mount"
          ];
        };
        docker-planka = {
          requires = [
            "docker-network-planka.service"
            "mnt-data3.mount"
          ];
          after = [
            "docker-network-planka.service"
            "mnt-data3.mount"
          ];
        };
      };

      networking.firewall.allowedTCPPorts = [ 1337 ];
    };
}
