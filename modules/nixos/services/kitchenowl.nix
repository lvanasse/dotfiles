{ inputs, ... }:
let
  kitchenowlEnvAge = "${inputs.secrets}/server/kitchenowl.env.age";
  kitchenowlEnvPlainRepo = "${inputs.secrets}/server/kitchenowl.env";
  kitchenowlEnvPlainOverride = ../../../overrides/kitchenowl.env;
in
{
  flake.modules.nixos."services.kitchenowl" =
    { config, lib, ... }:
    let
      hasKitchenowlEnvAge = builtins.pathExists kitchenowlEnvAge;
      hasKitchenowlEnvPlainRepo = builtins.pathExists kitchenowlEnvPlainRepo;
      hasKitchenowlEnvPlainOverride = builtins.pathExists kitchenowlEnvPlainOverride;
      hasKitchenowlEnv =
        hasKitchenowlEnvAge || hasKitchenowlEnvPlainRepo || hasKitchenowlEnvPlainOverride;
      kitchenowlEnvPath =
        if hasKitchenowlEnvAge then
          config.age.secrets."kitchenowl-env".path
        else if hasKitchenowlEnvPlainOverride then
          toString kitchenowlEnvPlainOverride
        else
          toString kitchenowlEnvPlainRepo;
      appDataRoot = "/mnt/ssd/appdata/docker/kitchenowl";
      defaultJwtSecret = builtins.hashString "sha256" "kitchenowl-jwt-secret";
    in
    {
      age.secrets = lib.mkIf hasKitchenowlEnvAge {
        "kitchenowl-env" = {
          file = kitchenowlEnvAge;
          path = "/run/agenix/kitchenowl-env";
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };

      systemd.tmpfiles.rules = [
        "d ${appDataRoot} 0755 root root -"
      ];

      virtualisation.oci-containers.containers.kitchenowl = {
        image = "tombursch/kitchenowl:latest";
        environment = lib.optionalAttrs (!hasKitchenowlEnv) {
          JWT_SECRET_KEY = defaultJwtSecret;
        };
        environmentFiles = lib.optional hasKitchenowlEnv kitchenowlEnvPath;
        volumes = [ "${appDataRoot}:/data" ];
        ports = [ "8086:8080" ];
        extraOptions = [
          "--label=com.centurylinklabs.watchtower.enable=true"
        ];
      };

      systemd.services.docker-kitchenowl = {
        requires = [ "mnt-ssd.mount" ];
        after = [ "mnt-ssd.mount" ];
      };

      networking.firewall.allowedTCPPorts = [ 8086 ];
    };
}
