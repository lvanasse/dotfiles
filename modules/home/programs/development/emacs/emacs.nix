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
      spacemacsTemplateOrg = ../../../../../emacs/spacemacs.org;
      spacemacsTemplate = builtins.readFile (
        pkgs.runCommand "tangle-spacemacs" { nativeBuildInputs = [ pkgs.emacs-nox ]; } ''
          cp ${spacemacsTemplateOrg} config.org
          emacs --batch \
            --eval "(require 'org)" \
            --eval "(org-babel-tangle-file \"config.org\")"
          cp config.el "$out"
        ''
      );
      copilotCliPkg = pkgs.llm-agents.copilot-cli;
      copilotCliWrapped = pkgs.writeShellScriptBin "copilot" ''
        exec ${lib.getExe copilotCliPkg} \
          --allow-all-tools \
          --allow-all-paths \
          --allow-all-urls \
          "$@"
      '';
      spacemacsConfig =
        builtins.replaceStrings
          [
            "__MU_SITE_LISP_MU4E__"
            "__MU_SITE_LISP_MU__"
            "__MU_SITE_LISP__"
            "__MU_BIN__"
            "__ISYNC_BIN__"
            "__MSMTP_BIN__"
            "__SPACEMACS_STARTUP_BANNER__"
          ]
          [
            "${pkgs.mu}/share/emacs/site-lisp/mu4e"
            "${pkgs.mu}/share/emacs/site-lisp/mu"
            "${pkgs.mu}/share/emacs/site-lisp"
            "${pkgs.mu}/bin/mu"
            "${pkgs.isync}/bin/mbsync"
            "${pkgs.msmtp}/bin/msmtp"
            "${config.home.homeDirectory}/.config/emacs/spacemacs-home-buffer.jpeg"
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

      home.packages = [
        copilotCliWrapped
      ];

      home.file.".spacemacs".text = spacemacsConfig;

      xdg.configFile."emacs/spacemacs-home-buffer.jpeg".source =
        ../../../../../wallpapers/shield-of-the-nation.jpg;

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
            --eval "(progn (when (fboundp 'my/mu4e-open-inbox) (my/mu4e-open-inbox)) nil)"
        '';
      };

      home.file.".local/bin/emacs-home-frame" = {
        executable = true;
        text = ''
          #!${pkgs.bash}/bin/bash
          emacsclient_bin="${config.programs.emacs.finalPackage}/bin/emacsclient"
          emacs_bin="${config.programs.emacs.finalPackage}/bin/emacs"

          if [ "$#" -gt 0 ]; then
            exec "$emacsclient_bin" -n -c -a "" "$@"
          fi

          if ! "$emacsclient_bin" --eval t >/dev/null 2>&1; then
            "$emacs_bin" --fg-daemon >/dev/null 2>&1 &
            for _ in $(seq 1 50); do
              if "$emacsclient_bin" --eval t >/dev/null 2>&1; then
                break
              fi
              sleep 0.1
            done
          fi

          exec "$emacsclient_bin" \
            -n \
            -a "" \
            --eval "(let ((frame (make-frame '((name . \"Emacs\") (title . \"Emacs\") (visibility . nil))))) (select-frame-set-input-focus frame) (with-selected-frame frame (when (fboundp 'spacemacs/home) (spacemacs/home))) (make-frame-visible frame) nil)"
        '';
      };

      home.file.".local/share/applications/emacs.desktop" = {
        text = ''
          [Desktop Entry]
          Name=Emacs
          GenericName=Text Editor
          Comment=Open Emacs directly on the Spacemacs home buffer
          Exec=${config.home.homeDirectory}/.local/bin/emacs-home-frame
          Icon=emacs
          Type=Application
          Terminal=false
          StartupNotify=true
          Categories=Development;TextEditor;
        '';
      };

      xdg.configFile."erc/README".text = ''
        ERC / Libera Chat setup

        Native Spacemacs entrypoints:
        - `SPC a c i` opens or raises ERC directly.
        - `SPC a c i D` is the compatible mail+IRC layout alias on the same dispatcher.
        - `SPC a c i j` prompts from your favorite channel list and joins or switches to that channel.
        - `SPC a c i E` is the raw ERC TLS prompt and is only a lower-level fallback.

        Current direct IRC target:
        - server: `irc.libera.chat`
        - port: `6697`
        - transport: TLS
        - nick: `lvanasse`
        - channels: `#emacs`, `#yocto`

        SASL auth is enabled and should come from `~/.authinfo` (or `~/.authinfo.gpg`), not the repo.
        Use entries like:

        machine Libera.Chat login YOUR_LIBERA_NICK password "YOUR_LIBERA_PASSWORD"
        machine irc.libera.chat port 6697 login YOUR_LIBERA_NICK password "YOUR_LIBERA_PASSWORD"

        Quote passwords in authinfo entries when they contain special characters
        (for example a leading `#`), or auth-source may parse them as empty.

        The managed IRC session also auto-connects shortly after Emacs startup.
        The first GUI frame of each Emacs process bootstraps the combined
        mail+IRC layout once, then later frames leave it alone.
        Favorite channels stay manual by default instead of autojoining.
        Desktop notifications are sent for direct private messages and channel
        messages containing your current nick. Plain IRC does not provide a
        standard threaded "reply" event, so reply alerts are approximated by
        nick mentions and PMs.
        Once connected, `/nick NEWNICK` is the native ERC way to change nicks.
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

      xdg.configFile."spotify-emacs/README".text = ''
        Spotify in Emacs

        Native Spacemacs entrypoints:
        - `SPC a m s p` toggles play/pause.
        - The native Spotify layer playback controls use DBus and work without API credentials.

        Optional search setup:
        - Credentials are managed by agenix at `${config.home.homeDirectory}/.config/spotify/private.el`
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
        Copilot CLI in Emacs

        Spacemacs entrypoints:
        - `SPC a a C` opens the managed `copilot` CLI in a dedicated right-side `vterm` panel.

        Native Spacemacs mail entrypoints:
        - `SPC a e m` opens mu4e directly in Inbox.
        - `SPC a e c` composes a new message.
        - `SPC a e u` updates mail and index.
        - `SPC a e l` opens the combined mail+IRC layout.

        Native Org/Calendar entrypoints:
        - `SPC a o a` opens the agenda.
        - `SPC a o c` captures a new Org item.
        - `SPC a o S` runs the managed CalDAV sync command.

        Authentication:
        1. Open the CLI with `SPC a a C`.
        2. Run `/login` if the CLI is not already authenticated.
        3. In the browser, sign into the GitHub account that has your Copilot entitlement.
        4. If Copilot comes from your work org, that org must allow Copilot CLI and you must authorize any required SSO.

        Runtime expectations:
        - The `copilot` executable is installed declaratively by Home Manager.
        - It starts with permissive read/network access, but local file edits and shell commands are denied by default.
        - A browser is needed for the first interactive login.
        - `gh auth status` is optional if you want to verify which GitHub account is active outside Emacs.
        - Terminal output does not fully reflow old lines after a resize, so very long previous output may still look wrapped oddly until you rerun or clear it.

        Debug checklist:
          - Confirm the CLI is visible:
          - `command -v copilot`
          - `copilot --help`
        - Run the repo smoke test:
          - `bash ${config.home.homeDirectory}/Code/personal/dotfiles/scripts/smoke-test-spacemacs-runtime.sh`
        - In Emacs, verify the commands resolve:
          - `SPC a a C`
        - When auth fails, inspect `*Messages*` and the Copilot CLI panel first.

        Default permission profile:
        - allowed without prompting: broad tool access, all paths, all URLs
        - denied even if requested: local `write` tools and all `shell` commands
        - caveat: MCP tools are still allowed, so an MCP server with side effects can still change remote systems unless you disable that server

        The GitHub Copilot CLI is installed declaratively from `pkgs.llm-agents.copilot-cli`, then wrapped with the default permission flags above.
        Launch the terminal workflow with `SPC a a C`.
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
