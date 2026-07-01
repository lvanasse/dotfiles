{ inputs, lib, ... }:
let
  cloudflaredEnvAge = "${inputs.secrets}/server/cloudflared.env.age";
  cloudflaredEnvPlainRepo = "${inputs.secrets}/server/cloudflared.env";
  cloudflaredEnvPlainOverride = ../../../overrides/cloudflared.env;
in
{
  flake.modules.nixos."services.cloudflared" =
    { ... }:
    let
      hasCloudflaredEnvAge = builtins.pathExists cloudflaredEnvAge;
      hasCloudflaredEnvPlainRepo = builtins.pathExists cloudflaredEnvPlainRepo;
      hasCloudflaredEnvPlainOverride = builtins.pathExists cloudflaredEnvPlainOverride;
      hasCloudflaredEnvPlain = hasCloudflaredEnvPlainRepo || hasCloudflaredEnvPlainOverride;
      hasCloudflaredEnv = hasCloudflaredEnvAge || hasCloudflaredEnvPlain;
      cloudflaredEnvPath =
        if hasCloudflaredEnvAge then "/run/agenix/cloudflared-env" else "/etc/cloudflared.env";
    in
    {
      age.secrets = lib.mkIf hasCloudflaredEnvAge {
        "cloudflared-env" = {
          file = cloudflaredEnvAge;
          path = "/run/agenix/cloudflared-env";
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };

      environment.etc."cloudflared.env" = lib.mkIf hasCloudflaredEnvPlain {
        source =
          if hasCloudflaredEnvPlainRepo then cloudflaredEnvPlainRepo else cloudflaredEnvPlainOverride;
        mode = "0400";
      };

      systemd.tmpfiles.rules = [
        "d /mnt/ssd/appdata/docker/cloudflared 0755 root root -"
      ];

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
        environmentFiles = lib.optional hasCloudflaredEnv cloudflaredEnvPath;
        volumes = [
          "/mnt/ssd/appdata/docker/cloudflared:/appdata"
        ];
        ports = [ "46495:46495" ];
      };

      systemd.services.docker-cloudflared = {
        requires = [
          "docker.service"
          "mnt-ssd.mount"
        ];
        after = [
          "docker.service"
          "mnt-ssd.mount"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 46495 ];
    };
}
