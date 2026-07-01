{ inputs, ... }:
let
  vaultwardenEnvAge = "${inputs.secrets}/server/vaultwarden.env.age";
  vaultwardenEnvPlainRepo = "${inputs.secrets}/server/vaultwarden.env";
  vaultwardenEnvPlainOverride = ../../../overrides/vaultwarden.env;
in
{
  flake.modules.nixos."services.vaultwarden" =
    { config, lib, ... }:
    let
      hasVaultwardenEnvAge = builtins.pathExists vaultwardenEnvAge;
      hasVaultwardenEnvPlainRepo = builtins.pathExists vaultwardenEnvPlainRepo;
      hasVaultwardenEnvPlainOverride = builtins.pathExists vaultwardenEnvPlainOverride;
      hasVaultwardenEnv =
        hasVaultwardenEnvAge || hasVaultwardenEnvPlainRepo || hasVaultwardenEnvPlainOverride;
      vaultwardenEnvPath =
        if hasVaultwardenEnvAge then
          config.age.secrets."vaultwarden-env".path
        else if hasVaultwardenEnvPlainOverride then
          toString vaultwardenEnvPlainOverride
        else
          toString vaultwardenEnvPlainRepo;
    in
    {
      age.secrets = lib.mkIf hasVaultwardenEnvAge {
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
          SIGNUPS_ALLOWED = "false";
          INVITATIONS_ALLOWED = "true";
          WEBSOCKET_ENABLED = "false";
        };
        environmentFiles = lib.optional hasVaultwardenEnv vaultwardenEnvPath;
        volumes = [
          "/mnt/ssd/appdata/docker/vaultwarden:/data"
        ];
        ports = [ "4743:80" ];
      };

      systemd.tmpfiles.rules = [
        "d /mnt/ssd/appdata/docker/vaultwarden 0750 root root -"
      ];

      systemd.services.docker-vaultwarden = {
        requires = [
          "mnt-ssd.mount"
        ];
        after = [
          "mnt-ssd.mount"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 4743 ];
    };
}
