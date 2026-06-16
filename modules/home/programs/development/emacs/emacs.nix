{ inputs, ... }:
{
  flake.modules.homeManager."programs.development.emacs" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      copilotCliPkg = pkgs.llm-agents.copilot-cli;
      copilotCliWrapped = pkgs.writeShellScriptBin "copilot" ''
        exec ${lib.getExe copilotCliPkg} \
          --allow-all-tools \
          --allow-all-paths \
          --allow-all-urls \
          "$@"
      '';
      vanillaRoot = "${config.xdg.configHome}/emacs-vanilla";
      emacsBin = "${config.programs.emacs.finalPackage}/bin/emacs";
      emacsClientBin = "${config.programs.emacs.finalPackage}/bin/emacsclient";
      systemctlBin = "${pkgs.systemd}/bin/systemctl";
      daemonServicePreStart =
        clientCmd:
        pkgs.writeShellScript "emacs-service-pre-start" ''
          set -eu

          emacsclient_bin="${clientCmd}"
          ps_bin="${pkgs.procps}/bin/ps"
          sleep_bin="${pkgs.coreutils}/bin/sleep"

          if "$emacsclient_bin" --eval '(daemonp)' >/dev/null 2>&1; then
            daemon_pid="$("$emacsclient_bin" --eval '(emacs-pid)' | tr -d '[:space:]')"
            daemon_ppid="$("$ps_bin" -o ppid= -p "$daemon_pid" 2>/dev/null | tr -d '[:space:]' || true)"

            if [ "$daemon_ppid" = "1" ]; then
              echo "Stopping existing Emacs daemon pid $daemon_pid before systemd startup"
              "$emacsclient_bin" --eval '(kill-emacs)' >/dev/null 2>&1 || kill "$daemon_pid" >/dev/null 2>&1 || true

              for _ in $(seq 1 50); do
                if ! kill -0 "$daemon_pid" 2>/dev/null; then
                  exit 0
                fi
                "$sleep_bin" 0.2
              done

              echo "Existing Emacs daemon pid $daemon_pid did not exit after SIGTERM; sending SIGKILL"
              kill -KILL "$daemon_pid" >/dev/null 2>&1 || true
              exit 0
            fi

            echo "Refusing to replace Emacs server owned by non-daemon pid $daemon_pid (ppid=$daemon_ppid)" >&2
            exit 1
          fi
        '';
      ensureDaemonScript =
        {
          clientCmd,
          serviceName,
          startCmd,
        }:
        ''
          if ! ${clientCmd} --eval t >/dev/null 2>&1; then
            if ! ${systemctlBin} --user start ${lib.escapeShellArg serviceName} >/dev/null 2>&1; then
              ${startCmd} >/dev/null 2>&1 &
            fi
            for _ in $(seq 1 50); do
              if ${clientCmd} --eval t >/dev/null 2>&1; then
                break
              fi
              sleep 0.1
            done
          fi
        '';
      spacemacs = import ./spacemacs-lib {
        inherit
          inputs
          config
          pkgs
          lib
          emacsBin
          emacsClientBin
          systemctlBin
          daemonServicePreStart
          ensureDaemonScript
          ;
      };
    in
    {
      programs.emacs = {
        enable = true;
        package = pkgs.emacs-unstable;
        extraPackages =
          epkgs: with epkgs; [
            gcmh
            gruvbox-theme
            vterm
            clipetty
            alert
            all-the-icons
            mu4e
            mu4e-alert
            counsel-spotify
            emoji-cheat-sheet-plus
            flycheck
            flycheck-pos-tip
            flyspell-correct
            flyspell-correct-ivy
            flyspell-lazy
            copilot-chat
            mcp
            nerd-icons
            pdf-tools
            slack
            bitbake-ts-mode
            nix-mode
            org-caldav
          ];
      };

      services.emacs = {
        enable = true;
        client.enable = true;
        startWithUserSession = "graphical";
      };

      systemd.user.services = {
        emacs.Service = {
          ExecStartPre = lib.mkForce [
            ""
            "${daemonServicePreStart emacsClientBin}"
          ];
          ExecStart = lib.mkForce [
            ""
            "${emacsBin} --init-directory ${lib.escapeShellArg vanillaRoot} --fg-daemon"
          ];
          Type = lib.mkForce "simple";
        };
      }
      // spacemacs.systemdUserServices;

      home.packages = [ copilotCliWrapped ] ++ spacemacs.homePackages;

      home.file = {
        ".local/bin/emacs" = {
          executable = true;
          text = ''
            #!${pkgs.bash}/bin/bash
            emacsclient_bin="${emacsClientBin}"

            ${ensureDaemonScript {
              clientCmd = "\"$emacsclient_bin\"";
              serviceName = "emacs.service";
              startCmd = "${emacsBin} --init-directory ${lib.escapeShellArg vanillaRoot} --fg-daemon";
            }}

            exec "$emacsclient_bin" -n -c -a "" "$@"
          '';
        };

        ".local/share/applications/emacs.desktop" = {
          text = ''
            [Desktop Entry]
            Name=Emacs
            GenericName=Text Editor
            Comment=Open a new frame on the vanilla Emacs daemon
            Exec=${config.home.homeDirectory}/.local/bin/emacs
            Icon=emacs
            Type=Application
            Terminal=false
            StartupNotify=true
            Categories=Development;TextEditor;
          '';
        };
      }
      // spacemacs.homeFiles;

      home.activation = spacemacs.homeActivations;

      xdg.configFile = spacemacs.xdgConfigFiles // {
        "emacs-vanilla/init.el".text = ''
          ;; Managed by Home Manager.
          ;; This file is intentionally minimal so `emacs` starts as close to
          ;; vanilla as possible while remaining isolated from Spacemacs state.
        '';
      };
    };
}
