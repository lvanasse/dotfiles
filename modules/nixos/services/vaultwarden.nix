{ inputs, ... }:
let
  vaultwardenEnvAge = "${inputs.secrets}/server/vaultwarden.env.age";
in
{
  flake.modules.nixos."services.vaultwarden" =
    { config, lib, ... }:
    let
      hasVaultwardenEnv = builtins.pathExists vaultwardenEnvAge;
    in
    {
      age.secrets = lib.mkIf hasVaultwardenEnv {
        "vaultwarden-env" = {
          file = vaultwardenEnvAge;
          path = "/run/agenix/vaultwarden-env";
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };

      virtualisation.oci-containers.containers.vaultwarden = {
        image = "vaultwarden/server";
        environment = {
          SIGNUPS_ALLOWED = "true";
          INVITATIONS_ALLOWED = "true";
          WEBSOCKET_ENABLED = "false";
        };
        environmentFiles = lib.optional hasVaultwardenEnv config.age.secrets."vaultwarden-env".path;
        volumes = [
          "/mnt/storage/appdata/vaultwarden:/data"
        ];
        ports = [ "4743:80" ];
      };

      networking.firewall.allowedTCPPorts = [ 4743 ];
    };
}
