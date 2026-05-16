{ inputs, ... }:
{
  flake.modules.homeManager."programs.email" =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      enableAccount = true;
      homeDir = config.home.homeDirectory;
      infomaniakPasswordAge = "${inputs.secrets}/email/mail@ludovicvanasse.com-infomaniak.age";
      hasInfomaniakPassword = builtins.pathExists infomaniakPasswordAge;
      infomaniakPasswordPath = "${homeDir}/.config/mail/infomaniak-password";
      muIndexAfterMbsync = pkgs.writeShellScript "mu-index-after-mbsync" ''
        set -eu

        emacsclient_bin="${config.programs.emacs.finalPackage}/bin/emacsclient"
        mu_bin="${pkgs.mu}/bin/mu"
        emacs_index_elisp='
          (progn
            (require (quote mu4e))
            (unless (mu4e-running-p)
              (mu4e (quote background)))
            (let ((deadline (+ (float-time) ${toString 300}))
                  (completed nil)
                  (status nil)
                  (wait-step 0.1))
              (while (and mu4e--server-indexing (< (float-time) deadline))
                (sleep-for wait-step))
              (when mu4e--server-indexing
                (error "Timed out waiting for an existing mu4e index run to finish"))
              (let ((hook (lambda ()
                            (setq completed t)
                            (setq status mu4e-index-update-status))))
                (unwind-protect
                    (progn
                      (add-hook (quote mu4e-index-updated-hook) hook)
                      (mu4e-update-index)
                      (while (and (not completed) (< (float-time) deadline))
                        (sleep-for wait-step))
                      (unless completed
                        (error "Timed out waiting for mu4e-update-index to finish"))
                      (princ
                       (format
                        "mu4e index completed: checked=%s updated=%s cleaned-up=%s"
                        (plist-get status :checked)
                        (plist-get status :updated)
                        (plist-get status :cleaned-up))))
                  (remove-hook (quote mu4e-index-updated-hook) hook)))))'

        if "$emacsclient_bin" --eval t >/dev/null 2>&1; then
          echo "Running mu index via Emacs daemon (mu4e-update-index)"
          exec "$emacsclient_bin" --eval "$emacs_index_elisp"
        fi

        echo "Emacs daemon unavailable; falling back to mu index"
        exec "$mu_bin" index
      '';
    in
    {
      programs.mu.enable = true;
      programs.mbsync.enable = true;
      programs.msmtp.enable = true;

      accounts.email.maildirBasePath = "mail";

      accounts.email.accounts.ludovic =
        {
          address = "mail@ludovicvanasse.com";
          userName = "mail@ludovicvanasse.com";
          realName = "Ludovic Vanasse";
          primary = true;

          imap = {
            host = "mail.infomaniak.com";
            port = 993;
            tls.enable = true;
          };
          smtp = {
            host = "mail.infomaniak.com";
            port = 587;
            tls = {
              enable = true;
              useStartTls = true;
            };
          };

          folders = {
            inbox = "Index";
            sent = "Sent";
            drafts = "Drafts";
            trash = "Trash";
          };

          mbsync = {
            enable = true;
            create = "maildir";
            expunge = "both";
          };
          msmtp.enable = true;
          mu.enable = true;
        }
        // lib.optionalAttrs hasInfomaniakPassword {
          passwordCommand = "cat ${infomaniakPasswordPath}";
        };

      services.mbsync = lib.mkIf enableAccount {
        enable = true;
        frequency = "*:0/10"; # every 10 minutes
      };

      systemd.user.services.mbsync.Service.ExecStopPost = lib.mkIf enableAccount [
        "${muIndexAfterMbsync}"
      ];

      home.activation.mu-init = lib.hm.dag.entryAfter [ "mbsync" ] ''
        MU_STORE="${config.xdg.cacheHome}/mu"
        if [ ! -d "$MU_STORE" ]; then
          ${pkgs.mu}/bin/mu init --maildir ${config.home.homeDirectory}/mail \
            --my-address=mail@ludovicvanasse.com
          ${pkgs.mu}/bin/mu index
        fi
      '';
    };
}
