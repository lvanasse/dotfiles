{ inputs, ... }:
let
  vikunjaEnvAge = "${inputs.secrets}/server/vikunja.env.age";
  vikunjaEnvPlainRepo = "${inputs.secrets}/server/vikunja.env";
  vikunjaEnvPlainOverride = ../../../overrides/vikunja.env;
in
{
  flake.modules.nixos."services.vikunja" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hasVikunjaEnvAge = builtins.pathExists vikunjaEnvAge;
      hasVikunjaEnvPlainRepo = builtins.pathExists vikunjaEnvPlainRepo;
      hasVikunjaEnvPlainOverride = builtins.pathExists vikunjaEnvPlainOverride;
      hasVikunjaEnv = hasVikunjaEnvAge || hasVikunjaEnvPlainRepo || hasVikunjaEnvPlainOverride;
      vikunjaEnvPath =
        if hasVikunjaEnvAge then
          config.age.secrets."vikunja-env".path
        else if hasVikunjaEnvPlainOverride then
          toString vikunjaEnvPlainOverride
        else
          toString vikunjaEnvPlainRepo;
      appDataRoot = "/mnt/data3/appdata/vikunja";
      defaultDbPassword = builtins.hashString "sha256" "vikunja-db-password";
      defaultJwtSecret = builtins.hashString "sha256" "vikunja-jwt-secret";
    in
    {
      systemd.services.docker-network-vikunja = {
        description = "Create docker network for Vikunja";
        wantedBy = [ "docker.service" ];
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          if ! ${pkgs.docker_29}/bin/docker network inspect vikunja >/dev/null 2>&1; then
            ${pkgs.docker_29}/bin/docker network create vikunja >/dev/null
          fi
        '';
      };

      age.secrets = lib.mkIf hasVikunjaEnvAge {
        "vikunja-env" = {
          file = vikunjaEnvAge;
          path = "/run/agenix/vikunja-env";
        };
      };

      systemd.tmpfiles.rules = [
        "d ${appDataRoot} 0755 root root -"
        "d ${appDataRoot}/files 0755 1000 1000 -"
        "d ${appDataRoot}/db 0755 root root -"
      ];

      virtualisation.oci-containers.containers.vikunja-postgres = {
        image = "postgres:16-alpine";
        environment = {
          POSTGRES_USER = "vikunja";
          POSTGRES_DB = "vikunja";
        }
        // lib.optionalAttrs (!hasVikunjaEnv) {
          POSTGRES_PASSWORD = defaultDbPassword;
        };
        environmentFiles = lib.optional hasVikunjaEnv vikunjaEnvPath;
        volumes = [ "${appDataRoot}/db:/var/lib/postgresql/data" ];
        extraOptions = [
          "--network=vikunja"
          "--network-alias=vikunja-db"
          "--label=com.centurylinklabs.watchtower.enable=true"
        ];
      };

      virtualisation.oci-containers.containers.vikunja = {
        image = "vikunja/vikunja:latest";
        dependsOn = [ "vikunja-postgres" ];
        environment = {
          VIKUNJA_SERVICE_PUBLICURL = "https://vikunja.ludovicvanasse.com/";
          VIKUNJA_SERVICE_ENABLEREGISTRATION = "false";
          VIKUNJA_DATABASE_TYPE = "postgres";
          VIKUNJA_DATABASE_HOST = "vikunja-db";
          XDG_CACHE_HOME = "/tmp/.cache";
        }
        // lib.optionalAttrs (!hasVikunjaEnv) {
          VIKUNJA_DATABASE_USER = "vikunja";
          VIKUNJA_DATABASE_DATABASE = "vikunja";
          VIKUNJA_DATABASE_PASSWORD = defaultDbPassword;
          VIKUNJA_SERVICE_JWTSECRET = defaultJwtSecret;
        };
        environmentFiles = lib.optional hasVikunjaEnv vikunjaEnvPath;
        volumes = [ "${appDataRoot}/files:/app/vikunja/files" ];
        ports = [ "3456:3456" ];
        extraOptions = [
          "--network=vikunja"
          "--label=com.centurylinklabs.watchtower.enable=true"
        ];
      };

      systemd.services = {
        docker-vikunja-postgres = {
          requires = [
            "docker-network-vikunja.service"
            "mnt-data3.mount"
          ];
          after = [
            "docker-network-vikunja.service"
            "mnt-data3.mount"
          ];
        };
        docker-vikunja = {
          requires = [
            "docker-network-vikunja.service"
            "mnt-data3.mount"
          ];
          after = [
            "docker-network-vikunja.service"
            "mnt-data3.mount"
          ];
          startLimitIntervalSec = 0;
          serviceConfig = {
            RestartSec = 5;
          };
        };
      };

      networking.firewall.allowedTCPPorts = [ 3456 ];
    };
}
