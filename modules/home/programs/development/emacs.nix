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
      spacemacsTemplate = builtins.readFile ./spacemacs.template.el;
      spacemacsConfig = builtins.replaceStrings
        [
          "__MU_SITE_LISP_MU4E__"
          "__MU_SITE_LISP_MU__"
          "__MU_SITE_LISP__"
          "__MU_BIN__"
          "__ISYNC_BIN__"
          "__MSMTP_BIN__"
          "__CURL_BIN__"
        ]
        [
          "${pkgs.mu}/share/emacs/site-lisp/mu4e"
          "${pkgs.mu}/share/emacs/site-lisp/mu"
          "${pkgs.mu}/share/emacs/site-lisp"
          "${pkgs.mu}/bin/mu"
          "${pkgs.isync}/bin/mbsync"
          "${pkgs.msmtp}/bin/msmtp"
          "${pkgs.curl}/bin/curl"
        ]
        spacemacsTemplate;
      emacsServicePreStart = pkgs.writeShellScript "emacs-service-pre-start" ''
        set -eu

        emacsclient_bin="${config.programs.emacs.finalPackage}/bin/emacsclient"
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
    in
    {
      programs.emacs = {
        enable = true;
        package = pkgs.emacs-unstable;
        extraPackages =
          epkgs: with epkgs; [
            gruvbox-theme
            vterm
            clipetty
            alert
            all-the-icons
            copilot
            mu4e
            mu4e-alert
            copilot-chat
            counsel-spotify
            emoji-cheat-sheet-plus
            flycheck
            flycheck-pos-tip
            flyspell-correct
            flyspell-correct-ivy
            mcp
            nerd-icons
            pdf-tools
            slack
            aidermacs
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

      systemd.user.services.emacs.Service = {
        ExecStartPre = lib.mkForce [
          ""
          "${emacsServicePreStart}"
        ];
        ExecStart = lib.mkForce [
          ""
          "${config.programs.emacs.finalPackage}/bin/emacs --fg-daemon"
        ];
      };

      home.file.".spacemacs".text = spacemacsConfig;

      home.file.".emacs.d" = {
        source = inputs.spacemacs;
        recursive = true;
      };

      home.file.".local/bin/emacs-mu4e-frame" = {
        executable = true;
        text = ''
          #!${pkgs.bash}/bin/bash
          exec ${config.programs.emacs.finalPackage}/bin/emacsclient \
            -n \
            -c \
            -a "" \
            -F '((name . "mu4e-mail") (title . "mu4e-mail"))' \
            --eval "(progn (require 'mu4e) (mu4e) nil)"
        '';
      };

      xdg.configFile."rcirc/README".text = ''
        rcirc / Libera Chat setup

        Native Spacemacs entrypoint:
        - `SPC a c i r` opens rcirc using the managed Libera defaults.

        Current direct IRC target:
        - server: `irc.libera.chat`
        - port: `6697`
        - transport: TLS

        If you want NickServ auth, put your credential in `~/.authinfo.gpg`.
        Example entry:

        machine irc.libera.chat port nickserv user YOUR_LIBERA_NICK password YOUR_LIBERA_PASSWORD

        The nick and default channels are configured in `.spacemacs`.
        Once connected, `/nick NEWNICK` is the native rcirc way to change nicks.
      '';

      xdg.configFile."slack/README".text = ''
        Slack in Emacs

        Native Spacemacs entrypoints:
        - `SPC a c s s` starts or reconnects Slack.
        - `SPC a c s j` joins a channel.
        - `SPC a c s d` opens a direct message.
        - `SPC a c s u` shows unread rooms.
        - `SPC a c s a` shows the activity feed.

        Private configuration:
        - Put your `slack-register-team` forms in
          `${config.home.homeDirectory}/.config/slack/private.el`
        - That file is loaded automatically if present.
        - Keep client ID, client secret, and token there, not in the repo.
        - Use a user token (`xoxp-...`) for the workspace you want Emacs to join.

        Setup flow:
        1. In the Slack API dashboard, create an app for the target workspace:
           https://api.slack.com/apps
        2. Under `OAuth & Permissions`, add the user scopes you need for chat.
        3. Install the app to the workspace and copy:
           - client ID
           - client secret
           - user OAuth token (`xoxp-...`)
        4. Save them in `${config.home.homeDirectory}/.config/slack/private.el`
        5. Restart Emacs or reload the file, then run `SPC a c s s`.

        Example:

        (slack-register-team
          :name "work"
          :default t
          :client-id "..."
          :client-secret "..."
          :token "xoxp-..."
          :subscribed-channels '(general))
      '';

      xdg.configFile."spotify/README".text = ''
        Spotify in Emacs

        Native Spacemacs entrypoints:
        - `SPC a m s p` toggles play/pause.
        - The native Spotify layer playback controls use DBus and work without API credentials.

        Optional search setup:
        - Put API credentials in `${config.home.homeDirectory}/.config/spotify/private.el`
        - That file is only loaded when present.
        - Keep only `counsel-spotify-client-id` and `counsel-spotify-client-secret` there.
        - Search features stay disabled until that file exists.

        Setup flow:
        1. Create an app at https://developer.spotify.com/dashboard
        2. Copy the client ID and client secret
        3. Save them in `${config.home.homeDirectory}/.config/spotify/private.el`
        4. Restart Emacs and run a `counsel-spotify` search command if desired

        Example:

        (setq counsel-spotify-client-id "..."
              counsel-spotify-client-secret "...")
      '';

      xdg.configFile."copilot-chat/README".text = ''
        Copilot Chat in Emacs

        Spacemacs entrypoints:
        - `SPC $ c` opens the native GitHub Copilot chat transient.
        - `SPC $ m` opens `*Mcp-Hub*` for MCP servers if you configure them later.
        - In a Copilot prompt buffer, `C-c C-c` sends and `C-c C-k` kills the chat.
        - In normal state inside chat, `,,` sends and `,k` kills the chat.

        Native Copilot completion bindings:
        - `C-M-<return>` accepts the current completion.
        - `C-M-S-<return>` accepts one word.
        - `C-M-<tab>` and `C-M-<iso-lefttab>` cycle suggestions.

        Native Spacemacs mail entrypoints:
        - `SPC a e m` opens mu4e.
        - `SPC a e c` composes a new message.
        - `SPC a e u` updates mail and index.

        Native Org/Calendar entrypoints:
        - `SPC a o a` opens the agenda.
        - `SPC a o c` captures a new Org item.
        - `SPC a o S` runs the managed CalDAV sync command.

        Authentication:
        1. For inline completion, run `SPC SPC copilot-install-server` once if needed.
        2. Run `SPC SPC copilot-login` for the completion side if prompted.
        3. Open chat with `SPC $ c` and choose the chat action from the transient.
        4. Send a prompt.
        5. Follow the device-flow instructions shown by `copilot-chat`.
        6. In the browser, sign into the GitHub account that has the Copilot license.
        7. If your work org uses SAML SSO, authorize it there too.

        Managed storage paths:
        - token: `${config.home.homeDirectory}/.config/copilot-chat/github-token`
        - cache: `${config.home.homeDirectory}/.local/state/copilot-chat/token-cache`
        - saved chats: `${config.home.homeDirectory}/.local/state/copilot-chat/chats/`

        Runtime expectations:
        - `curl` must be available (managed by this config).
        - `node` and `npm` must be in `PATH` for the Copilot language server.
        - A browser is needed for the first interactive device-flow login.
        - `python3` is only needed later if you add MCP servers that require it.
        - `gh auth status` is optional if you want to verify which GitHub account
          is active outside Emacs.

        Debug checklist:
        - Confirm auth files exist:
          - `${config.home.homeDirectory}/.config/copilot-chat/github-token`
          - `${config.home.homeDirectory}/.local/state/copilot-chat/token-cache` (after first login)
        - Confirm `node`, `npm`, and `curl` are visible from the shell that launches Emacs:
          - `command -v node npm curl`
        - Run the repo smoke test:
          - `bash ${config.home.homeDirectory}/Code/personal/dotfiles/scripts/smoke-test-spacemacs-runtime.sh`
        - In Emacs, verify the commands resolve:
          - `SPC SPC copilot-login`
          - `SPC $ c`
        - When auth fails, inspect `*Messages*` and the Copilot chat buffer first.

        Model behavior:
        - The managed default is `gpt-4.1`.
        - Use the native Copilot chat transient to change model for the current chat.
      '';

      xdg.configFile."spell-checking/README".text = ''
        Spell checking in Emacs

        Native Spacemacs entrypoints:
        - `SPC t S` toggles flyspell in the current buffer.
        - `SPC S b` checks the whole buffer.
        - `SPC S s` corrects the word at point.
        - `SPC S d` changes dictionary.

        Managed backend:
        - `aspell` is installed declaratively.
        - Default dictionary is `en`.
        - Switch to French with `SPC S d` when needed.
      '';

      xdg.configFile."tabs/README".text = ''
        Tabs in Emacs

        Native Spacemacs entrypoints:
        - `g t` moves to the next tab.
        - `g T` moves to the previous tab.
        - `g C-t` moves the current tab right.
        - `g C-S-t` moves the current tab left.
        - `C-c t s` switches tab groups.
        - `C-c t p` groups tabs by project.
      '';

      home.activation.ensureEmacsStateDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p \
          "${config.home.homeDirectory}/.local/state/copilot-chat/chats"
      '';

      home.activation.removeXDGInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        XDG_INIT="${config.home.homeDirectory}/.config/emacs/init.el"
        if [ -L "$XDG_INIT" ] || [ -f "$XDG_INIT" ]; then
          echo "[home.activation] Removing legacy XDG init at $XDG_INIT" >&2
          rm -f "$XDG_INIT"
          rmdir --ignore-fail-on-non-empty "${config.home.homeDirectory}/.config/emacs" 2>/dev/null || true
        fi
      '';
    };
}
