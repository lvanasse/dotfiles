{ ... }:
{
  flake.modules.nixos."services.cloudflared" =
    { config, ... }:
    {
      # TODO: Move TUNNEL_TOKEN to agenix secret
      virtualisation.oci-containers.containers.cloudflared = {
        image = "cloudflare/cloudflared:latest";
        cmd = [ "tunnel" "--no-autoupdate" "run" ];
        environment = {
          # TUNNEL_TOKEN should be set via environmentFiles with agenix
        };
        environmentFiles = [
          # config.age.secrets.cloudflared-env.path
        ];
        extraOptions = [ "--network=host" ];
      };
    };
}
