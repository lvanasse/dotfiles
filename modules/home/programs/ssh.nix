{
  inputs,
  lib,
  ...
}:
let
  personalPub = "${inputs.secrets}/keys/id_ed25519_personal.pub";
  workPub = "${inputs.secrets}/keys/id_ed25519_work.pub";
  hasPersonalPub = builtins.pathExists personalPub;
  hasWorkPub = builtins.pathExists workPub;
in
{
  flake.modules.homeManager."programs.ssh" =
    { pkgs, ... }:
    let
      wakeWorkLaptop = pkgs.writeShellScriptBin "wake-work-laptop" ''
        set -euo pipefail

        mac="''${WORK_LAPTOP_WOL_MAC:-}"
        if [ -z "$mac" ]; then
          echo "wake-work-laptop: set WORK_LAPTOP_WOL_MAC to the work laptop NIC MAC address" >&2
          exit 1
        fi

        gateway_host="''${WORK_LAPTOP_WOL_GATEWAY:-gateway-ts}"
        broadcast="''${WORK_LAPTOP_WOL_BROADCAST:-192.168.0.255}"
        port="''${WORK_LAPTOP_WOL_PORT:-9}"

        # Tailscale gets us to the relay host; the relay host emits the LAN magic packet.
        exec ${pkgs.openssh}/bin/ssh "$gateway_host" \
          "/run/current-system/sw/bin/wakeonlan -i '$broadcast' -p '$port' '$mac'"
      '';
    in
    {
      home.file =
        (lib.optionalAttrs hasPersonalPub {
          ".ssh/id_ed25519_personal.pub".source = personalPub;
        })
        // (lib.optionalAttrs hasWorkPub {
          ".ssh/id_ed25519_work.pub".source = workPub;
        })
        // {
          ".local/bin/wake-pc" = {
            executable = true;
            text = ''
              #!${pkgs.bash}/bin/bash
              set -euo pipefail

              if command -v wake-pc-lan >/dev/null 2>&1; then
                exec wake-pc-lan "$@"
              fi

              exec ${pkgs.openssh}/bin/ssh server-ts wake-pc-lan "$@"
            '';
          };
        };

      # SSH configuration for different keys
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false; # Disable default config to avoid future warnings

        settings = {
          # Personal hosts (LAN aliases)
          "pc" = {
            hostname = "192.168.0.100";
            user = "ludovic";
            identityFile = "~/.ssh/id_ed25519_personal";
            pubkeyAuthentication = true;
            identitiesOnly = true;
            identityAgent = "none";
          };

          "server" = {
            hostname = "192.168.0.50";
            user = "ludovic";
            identityFile = "~/.ssh/id_ed25519_personal";
            pubkeyAuthentication = true;
            identitiesOnly = true;
            identityAgent = "none";
          };

          "gateway" = {
            hostname = "192.168.0.1";
            user = "ludovic";
            identityFile = "~/.ssh/id_ed25519_personal";
            pubkeyAuthentication = true;
            identitiesOnly = true;
            identityAgent = "none";
          };

          "laptop" = {
            hostname = "laptop";
            user = "ludovic";
            identityFile = "~/.ssh/id_ed25519_personal";
            pubkeyAuthentication = true;
            identitiesOnly = true;
            identityAgent = "none";
          };

          # Personal hosts (Tailscale aliases)
          "pc-ts" = {
            hostname = "pc.tail7e8d6c.ts.net";
            user = "ludovic";
            identityFile = "~/.ssh/id_ed25519_personal";
            pubkeyAuthentication = true;
            identitiesOnly = true;
            identityAgent = "none";
          };

          "server-ts" = {
            hostname = "server.tail7e8d6c.ts.net";
            user = "ludovic";
            identityFile = "~/.ssh/id_ed25519_personal";
            pubkeyAuthentication = true;
            identitiesOnly = true;
            identityAgent = "none";
          };

          "gateway-ts" = {
            hostname = "gateway.tail7e8d6c.ts.net";
            user = "ludovic";
            identityFile = "~/.ssh/id_ed25519_personal";
            pubkeyAuthentication = true;
            identitiesOnly = true;
            identityAgent = "none";
          };

          "work-laptop" = {
            hostname = "work-laptop.tail7e8d6c.ts.net";
            user = "ludovic";
            identityFile = "~/.ssh/id_ed25519_personal";
            pubkeyAuthentication = true;
            identitiesOnly = true;
            identityAgent = "none";
          };

          # Steam Deck (SteamOS)
          "steamdeck" = {
            hostname = "192.168.0.105";
            user = "deck";
            identityFile = "~/.ssh/id_ed25519_personal";
            pubkeyAuthentication = true;
            identitiesOnly = true;
            identityAgent = "none";
          };

          # Personal GitHub account
          "github-personal" = {
            hostname = "github.com";
            user = "git";
            identityFile = "~/.ssh/id_ed25519_personal";
            pubkeyAuthentication = true;
            identitiesOnly = true;
          };

          # Work Bitbucket account via alias
          "bitbucket-work" = {
            hostname = "bitbucket.org";
            user = "git";
            identityFile = "~/.ssh/id_ed25519_work";
            pubkeyAuthentication = true;
            identitiesOnly = true;
            controlMaster = "no";
            controlPath = "none";
          };

          # Work Bitbucket account via canonical host (for initial clones)
          "bitbucket.org" = {
            hostname = "bitbucket.org";
            user = "git";
            identityFile = "~/.ssh/id_ed25519_work";
            pubkeyAuthentication = true;
            identitiesOnly = true;
            controlMaster = "no";
            controlPath = "none";
          };

          # Default GitHub (work)
          "github.com" = {
            hostname = "github.com";
            user = "git";
            identityFile = "~/.ssh/id_ed25519_work";
            pubkeyAuthentication = true;
            identitiesOnly = true;
          };

          # Codeberg (personal)
          "codeberg.org" = {
            hostname = "codeberg.org";
            user = "git";
            identityFile = "~/.ssh/id_ed25519_personal";
            pubkeyAuthentication = true;
            identitiesOnly = true;
          };

          # Default SSH settings for all hosts
          "*" = {
            serverAliveInterval = 60;
            serverAliveCountMax = 3;
            pubkeyAuthentication = false;
            passwordAuthentication = true;
            preferredAuthentications = "publickey,password,keyboard-interactive";
            identityAgent = "none";
            # Common SSH defaults that we want to keep
            compression = true;
            controlMaster = "auto";
            controlPath = "~/.ssh/master-%r@%h:%p";
            controlPersist = "10m";
            addKeysToAgent = "yes";
          };
        };
      };

      home.packages = [ wakeWorkLaptop ];
    };
}
