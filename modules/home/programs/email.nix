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

        lock_file="${config.xdg.cacheHome}/mu/index-after-mbsync.lock"
        emacsclient_bin="${config.programs.emacs.finalPackage}/bin/emacsclient"
        mu_bin="${pkgs.mu}/bin/mu"
        flock_bin="${pkgs.util-linux}/bin/flock"
        emacs_index_elisp='
          (progn
            (require (quote cl-lib))
            (require (quote mu4e))
            (defun my/mu-index-helper--wait-until (predicate deadline)
              (while (and (not (funcall predicate))
                          (< (float-time) deadline))
                (accept-process-output nil 0.2))
              (funcall predicate))
            (defun my/mu-index-helper--mu-process-p (proc)
              (let* ((command (ignore-errors (process-command proc)))
                     (argv (and (listp command)
                                (mapconcat (lambda (part)
                                             (format "%s" part))
                                           command
                                           " ")))
                     (name (process-name proc)))
                (or (and argv (string-match-p "\\\\bmu\\\\b" argv))
                    (string-match-p "mu4e\\|mu-server\\|mu index" name))))
            (defun my/mu-index-helper--mu-processes ()
              (cl-remove-if-not
               (lambda (proc)
                 (and (process-live-p proc)
                      (my/mu-index-helper--mu-process-p proc)))
               (process-list)))
            (defun my/mu-index-helper--stop-stale-processes ()
              (dolist (proc (my/mu-index-helper--mu-processes))
                (ignore-errors (interrupt-process proc))
                (my/mu-index-helper--wait-until
                 (lambda () (not (process-live-p proc)))
                 (+ (float-time) 3.0))
                (when (process-live-p proc)
                  (ignore-errors (delete-process proc))))
              (setq mu4e--server-indexing nil))
            (defun my/mu-index-helper--ensure-daemon-state ()
              (unless (mu4e-running-p)
                (mu4e (quote background))))
            (defun my/mu-index-helper--wait-for-existing-index ()
              (let ((deadline (+ (float-time) 15.0)))
                (unless (my/mu-index-helper--wait-until
                         (lambda () (not mu4e--server-indexing))
                         deadline)
                  (princ "Existing mu4e index run looks stale; resetting it\n")
                  (my/mu-index-helper--stop-stale-processes)
                  (my/mu-index-helper--ensure-daemon-state))))
            (my/mu-index-helper--ensure-daemon-state)
            (my/mu-index-helper--wait-for-existing-index)
            (unless (mu4e-running-p)
              (mu4e (quote background)))
            (let ((deadline (+ (float-time) ${toString 300}))
                  (completed nil)
                  (status nil)
                  (wait-step 0.1))
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
                        (my/mu-index-helper--stop-stale-processes)
                        (error "Timed out waiting for mu4e-update-index to finish"))
                      (princ
                       (format
                        "mu4e index completed: checked=%s updated=%s cleaned-up=%s"
                        (plist-get status :checked)
                        (plist-get status :updated)
                        (plist-get status :cleaned-up))))
                  (remove-hook (quote mu4e-index-updated-hook) hook)))))'

        mkdir -p "$(dirname "$lock_file")"
        exec 9>"$lock_file"
        "$flock_bin" -w 600 9

        if "$emacsclient_bin" --eval t >/dev/null 2>&1; then
          echo "Running mu index via Emacs daemon (mu4e-update-index)"
          exec "$emacsclient_bin" --eval "$emacs_index_elisp"
        fi

        echo "Emacs daemon unavailable; skipping index (will happen when mu4e starts)"
        exit 0
      '';
    in
    {
      programs.mu.enable = true;
      programs.mbsync.enable = true;
      programs.msmtp.enable = true;

      accounts.email.maildirBasePath = "mail";

      accounts.email.accounts.ludovic = {
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
