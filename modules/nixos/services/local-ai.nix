{ ... }:
{
  flake.modules.nixos."services.local-ai" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.localAi;
      llamaServer = lib.getExe' pkgs.llama-cpp-vulkan "llama-server";
      startLocalAi = pkgs.writeShellApplication {
        name = "start-local-ai";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.tailscale
        ];
        text = ''
          set -euo pipefail

          tailscale_address="$(tailscale ip -4 | head -n 1)"
          if [ -z "$tailscale_address" ]; then
            echo "No Tailscale IPv4 address is available" >&2
            exit 1
          fi

          exec ${llamaServer} \
            --model ${lib.escapeShellArg cfg.modelPath} \
            --alias qwen3.5-9b \
            --host "$tailscale_address" \
            --port ${toString cfg.port} \
            --n-gpu-layers all \
            --flash-attn on \
            --jinja \
            --ctx-size ${toString cfg.contextSize} \
            --cache-type-k q8_0 \
            --cache-type-v q8_0 \
            --temp 0.6 \
            --top-k 20 \
            --top-p 0.95 \
            --min-p 0 \
            --parallel 1 \
            --cache-ram 2048 \
            --sleep-idle-seconds ${toString cfg.idleSeconds} \
            --metrics
        '';
      };
    in
    {
      options.services.localAi = {
        enable = lib.mkEnableOption "private llama.cpp inference on the server GPU";

        modelPath = lib.mkOption {
          type = lib.types.str;
          description = "Absolute path to the GGUF model outside the Nix store.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 8088;
          description = "TCP port on the Tailscale address.";
        };

        contextSize = lib.mkOption {
          type = lib.types.ints.positive;
          default = 32768;
          description = "Maximum model context in tokens.";
        };

        idleSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 300;
          description = "Idle time before llama-server unloads the model.";
        };
      };

      config = lib.mkIf cfg.enable {
        users.groups.local-ai = { };
        users.users.local-ai = {
          isSystemUser = true;
          group = "local-ai";
          extraGroups = [
            "render"
            "video"
          ];
        };

        systemd.services.local-ai = {
          description = "Private Qwen coding model on the RX 580";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [
            "network-online.target"
            "tailscaled.service"
          ];
          requires = [ "tailscaled.service" ];
          unitConfig.ConditionPathExists = cfg.modelPath;

          environment = {
            GGML_VK_VISIBLE_DEVICES = "0";
            RADV_PERFTEST = "nogttspill";
            XDG_CACHE_HOME = "/var/cache/local-ai";
          };

          serviceConfig = {
            Type = "simple";
            User = "local-ai";
            Group = "local-ai";
            ExecStart = lib.getExe startLocalAi;
            Restart = "on-failure";
            RestartSec = "10s";
            TimeoutStartSec = "5min";
            CacheDirectory = "local-ai";
            CacheDirectoryMode = "0700";
            UMask = "0077";
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            LockPersonality = true;
            CapabilityBoundingSet = "";
            RestrictAddressFamilies = [
              "AF_UNIX"
              "AF_INET"
              "AF_INET6"
              "AF_NETLINK"
            ];
          };
        };
      };
    };
}
