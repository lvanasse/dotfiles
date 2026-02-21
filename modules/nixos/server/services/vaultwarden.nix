{ ... }:
{
  flake.modules.nixos."server.vaultwarden" =
    { config, ... }:
    {
      # TODO: Move ADMIN_TOKEN to agenix secret
      virtualisation.oci-containers.containers.vaultwarden = {
        image = "vaultwarden/server:latest";
        environment = {
          SIGNUPS_ALLOWED = "false";
          INVITATIONS_ALLOWED = "true";
          WEBSOCKET_ENABLED = "true";
          # ADMIN_TOKEN should be set via environmentFiles with agenix
        };
        environmentFiles = [
          # config.age.secrets.vaultwarden-env.path
        ];
        volumes = [
          "/var/lib/vaultwarden:/data"
        ];
        ports = [ "4743:80" ];
      };

      networking.firewall.allowedTCPPorts = [ 4743 ];
    };
}
