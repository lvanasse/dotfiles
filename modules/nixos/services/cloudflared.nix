{ inputs, ... }:
let
  cloudflaredEnvAge = "${inputs.secrets}/server/cloudflared.env.age";
in
{
  flake.modules.nixos."services.cloudflared" =
    { config, lib, ... }:
    let
      hasCloudflaredEnv = builtins.pathExists cloudflaredEnvAge;
    in
    {
      age.secrets = lib.mkIf hasCloudflaredEnv {
        "cloudflared-env" = {
          file = cloudflaredEnvAge;
          path = "/run/agenix/cloudflared-env";
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };

      virtualisation.oci-containers.containers.cloudflared = {
        image = "figro/unraid-cloudflared-tunnel";
        autoStart = hasCloudflaredEnv;
        environment = {
          NO_AUTOUPDATE = "true";
          TUNNEL_RETRIES = "5";
          TUNNEL_TRANSPORT_PROTOCOL = "auto";
          TUNNEL_EDGE_IP_VERSION = "auto";
          TUNNEL_GRACE_PERIOD = "30s";
          TUNNEL_METRICS = "0.0.0.0:46495";
          TUNNEL_LOGLEVEL = "info";
        };
        environmentFiles = lib.optional hasCloudflaredEnv config.age.secrets."cloudflared-env".path;
        volumes = [
          "/mnt/storage/appdata/cloudflared:/appdata"
        ];
        ports = [ "46495:46495" ];
      };

      networking.firewall.allowedTCPPorts = [ 46495 ];
    };
}
