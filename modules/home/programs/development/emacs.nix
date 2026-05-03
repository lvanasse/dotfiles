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
          "__ISYNC_BIN__"
          "__MSMTP_BIN__"
          "__CURL_BIN__"
        ]
        [
          "${pkgs.mu}/share/emacs/site-lisp/mu4e"
          "${pkgs.mu}/share/emacs/site-lisp/mu"
          "${pkgs.mu}/share/emacs/site-lisp"
          "${pkgs.isync}/bin/mbsync"
          "${pkgs.msmtp}/bin/msmtp"
          "${pkgs.curl}/bin/curl"
        ]
        spacemacsTemplate;
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
            mu4e
            mu4e-alert
            copilot-chat
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

      systemd.user.services.emacs.Service.ExecStart = lib.mkForce [
        ""
        "${config.programs.emacs.finalPackage}/bin/emacs --fg-daemon"
      ];

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
