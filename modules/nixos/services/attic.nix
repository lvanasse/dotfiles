{ inputs, ... }:
let
  atticEnvironmentAge = "${inputs.secrets}/server/atticd.env.age";
in
{
  flake.modules.nixos."services.attic" =
    { config, lib, ... }:
    let
      hasAtticEnvironment = builtins.pathExists atticEnvironmentAge;
    in
    {
      age.secrets."atticd-env" = lib.mkIf hasAtticEnvironment {
        file = atticEnvironmentAge;
        path = "/run/agenix/atticd-env";
        mode = "0400";
      };

      services.atticd = lib.mkIf hasAtticEnvironment {
        enable = true;
        environmentFile = config.age.secrets."atticd-env".path;
        settings = {
          listen = "[::]:8080";
          jwt = { };
          chunking = {
            nar-size-threshold = 64 * 1024;
            min-size = 16 * 1024;
            avg-size = 64 * 1024;
            max-size = 256 * 1024;
          };
          garbage-collection = {
            interval = "12 hours";
            default-retention-period = "30 days";
          };
        };
      };

      warnings = lib.optional (!hasAtticEnvironment) ''
        Attic is configured but disabled until ${atticEnvironmentAge} exists.
      '';
    };
}
