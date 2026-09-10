{ inputs, lib, ... }:
let
  ntfyEnvAge = "${inputs.secrets}/server/ntfy.env.age";
  monitorTokenAge = "${inputs.secrets}/server/ntfy-monitor.token.age";
in
{
  flake.modules.nixos."services.ntfy" =
    {
      config,
      pkgs,
      ...
    }:
    let
      hasNtfyEnv = builtins.pathExists ntfyEnvAge;
      hasMonitorToken = builtins.pathExists monitorTokenAge;
      ntfyEnvPath = "/run/agenix/ntfy-env";
      monitorTokenPath = "/run/agenix/ntfy-monitor-token";
      ntfyTest = pkgs.writeShellApplication {
        name = "ntfy-test";
        runtimeInputs = [ pkgs.curl ];
        text = ''
          set -euo pipefail

          token="$(${pkgs.coreutils}/bin/tr -d '\n' < ${monitorTokenPath})"
          exec curl --fail --silent --show-error \
            --header "Authorization: Bearer $token" \
            --header "Title: Homelab notification test" \
            --header "Priority: default" \
            --header "Tags: test_tube" \
            --data "Authenticated test message from server" \
            http://127.0.0.1:2586/homelab-alerts
        '';
      };
    in
    {
      assertions = [
        {
          assertion = hasNtfyEnv;
          message = "ntfy requires ${ntfyEnvAge}.";
        }
        {
          assertion = hasMonitorToken;
          message = "ntfy test publisher requires ${monitorTokenAge}.";
        }
        {
          assertion = !(builtins.elem 2586 config.networking.firewall.allowedTCPPorts);
          message = "ntfy must not open TCP port 2586 directly.";
        }
      ];

      age.secrets."ntfy-env" = {
        file = ntfyEnvAge;
        path = ntfyEnvPath;
        owner = "root";
        group = "root";
        mode = "0400";
      };
      age.secrets."ntfy-monitor-token" = {
        file = monitorTokenAge;
        path = monitorTokenPath;
        owner = "root";
        group = "root";
        mode = "0400";
      };

      services.ntfy-sh = {
        enable = true;
        environmentFile = ntfyEnvPath;
        settings = {
          base-url = "https://ntfy.ludovicvanasse.com";
          listen-http = "0.0.0.0:2586";
          behind-proxy = true;
          auth-default-access = "deny-all";
          cache-duration = "24h";
        };
      };

      environment.systemPackages = [ ntfyTest ];

      systemd.services.ntfy-sh = {
        restartTriggers = [ ntfyEnvAge ];
      };

      # Port 2586 intentionally stays out of the LAN/WAN firewall. The existing
      # Cloudflare Tunnel reaches the native service at 192.168.0.50:2586.
    };
}
