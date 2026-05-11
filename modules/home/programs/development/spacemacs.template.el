;; Template rendered by modules/home/programs/development/emacs.nix.

(defun dotspacemacs/layers ()
  (setq-default
   dotspacemacs-distribution 'spacemacs
   dotspacemacs-enable-lazy-installation 'unused
   dotspacemacs-ask-for-lazy-installation t
   dotspacemacs-install-packages 'used-only
   dotspacemacs-configuration-layers '(
     better-defaults
     git
     org
     (tabs :variables tabs-icons t)
     (auto-completion :variables auto-completion-enable-snippets-in-popup t)
     spell-checking
     syntax-checking
     ivy
     lsp
     (treemacs :variables treemacs-use-follow-mode t)
     c-c++
     claude-code
     cmake
     docker
     github-copilot
     (mu4e :variables
            mu4e-installation-path "__MU_SITE_LISP_MU4E__"
            mu4e-enable-notifications t
            mu4e-enable-mode-line t)
     markdown
     nixos
     pdf
     python
     yaml
     (rcirc :variables rcirc-enable-authinfo-support t)
     rust
     slack
     spotify
     (shell :variables shell-default-shell 'vterm)
     shell-scripts
   )
   dotspacemacs-additional-packages '(gruvbox-theme vterm clipetty aidermacs all-the-icons nerd-icons counsel-spotify bitbake-ts-mode nix-mode json-mode org-caldav)
   dotspacemacs-excluded-packages '(forge)))

(defun dotspacemacs/init ()
  (setq-default
   dotspacemacs-editing-style 'vim
   dotspacemacs-elpa-https t
   dotspacemacs-verify-spacelpa-archives nil
   dotspacemacs-themes '(gruvbox-dark-hard)
   dotspacemacs-colorize-cursor-according-to-state t
   dotspacemacs-mode-line-theme 'spacemacs
   dotspacemacs-scratch-mode 'text-mode
   dotspacemacs-startup-banner nil
   dotspacemacs-startup-lists nil))

(defun dotspacemacs/user-init ()
  ;; Startup and LSP defaults tuned for interactive work rather than cold-start demos.
  (setq gc-cons-threshold (* 128 1024 1024)
        read-process-output-max (* 1024 1024)
        idle-update-delay 1.0
        fast-but-imprecise-scrolling t
        redisplay-skip-fontification-on-input t)
  (when (boundp 'native-comp-async-report-warnings-errors)
    (setq native-comp-async-report-warnings-errors 'silent))
  (when (boundp 'comp-async-report-warnings-errors)
    (setq comp-async-report-warnings-errors 'silent))
  (when (boundp 'warning-suppress-types)
    (add-to-list 'warning-suppress-types '(native-compiler))))

(defun dotspacemacs/user-config ()
  (setq-default
   whitespace-style '(face trailing tabs tab-mark)
   whitespace-line-column 100)

  (defun my/load-private-elisp (path)
    (when (file-readable-p path)
      (load path nil 'nomessage)))

  (defun my/copilot-chat-open ()
    (interactive)
    ;; Prefer an explicit load path over the stale autoload that can linger in
    ;; ~/.emacs.d/elpa after upstream function renames.
    (let ((shim (symbol-function 'copilot-chat-transient)))
      (when (eq shim #'my/copilot-chat-open)
        (fmakunbound 'copilot-chat-transient)))
    (require 'copilot-chat nil t)
    (unless (fboundp 'copilot-chat-transient)
      (user-error "copilot-chat-transient is unavailable; run Home Manager switch and restart Emacs"))
    (call-interactively #'copilot-chat-transient))
  (defalias 'copilot-chat-transient #'my/copilot-chat-open)

  ;; Keep GC modest again after startup.
  (add-hook 'emacs-startup-hook
            (lambda ()
              (setq gc-cons-threshold (* 32 1024 1024))))

  ;; Ensure Home Manager profiles are visible to GUI-launched Emacs.
  (dolist (path '("~/.nix-profile/bin" "~/.local/state/nix/profile/bin"))
    (let ((expanded (expand-file-name path)))
      (when (file-directory-p expanded)
        (add-to-list 'exec-path expanded)
        (setenv "PATH" (concat expanded path-separator (getenv "PATH"))))))

  (setq select-enable-clipboard t
        save-interprogram-paste-before-kill t)

  ;; The native github-copilot layer binds keys on this map in its :config,
  ;; but the installed copilot-chat package only defines it after loading the
  ;; prompt-mode file. Seed it early so the layer config does not explode.
  (defvar copilot-chat-prompt-mode-map (make-sparse-keymap))

  (setq user-full-name "Ludovic Vanasse"
        user-mail-address "mail@ludovicvanasse.com")

  (setq ispell-program-name "aspell"
        ispell-dictionary "en")

  (when (and (not (display-graphic-p))
             (require 'clipetty nil t))
    (global-clipetty-mode 1))

  (defun my/mu4e-compose-new ()
    (interactive)
    (unless (require 'mu4e nil t)
      (user-error "mu4e is not available; run Home Manager switch and restart Emacs"))
    (call-interactively #'mu4e-compose-new))

  (defconst my/mu4e-alert-query
    "flag:unread AND NOT flag:trashed AND (maildir:/ludovic/Index OR maildir:/ludovic/Promotions OR maildir:/ludovic/SocialNetworks)"
    "Unread mail query limited to the folders the user cares about.")

  (let* ((fish-candidates (list
                           (executable-find "fish")
                           (expand-file-name "~/.nix-profile/bin/fish")
                           (expand-file-name "~/.local/state/nix/profile/bin/fish")
                           "/run/current-system/sw/bin/fish"))
         (fish (seq-find #'file-executable-p fish-candidates)))
    (when fish
      (setq shell-file-name fish
            explicit-shell-file-name fish
            vterm-shell fish
            multi-term-program fish)
      (setenv "SHELL" fish)))

  (spacemacs/set-leader-keys
    "'" 'spacemacs/default-pop-shell)

  (add-hook 'before-save-hook #'delete-trailing-whitespace)

  (defun my/prog-mode-line-numbers ()
    (setq display-line-numbers-type 'absolute)
    (display-line-numbers-mode 1))
  (add-hook 'prog-mode-hook #'my/prog-mode-line-numbers)

  ;; Improve Makefile detection for mixed embedded trees.
  (add-to-list 'auto-mode-alist '("\\.mk\\'" . makefile-gmake-mode))
  (add-to-list 'auto-mode-alist '("Makefile\\." . makefile-gmake-mode))

  ;; Add Markdown detection
  (add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))
  (add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))

  ;; Yocto / BitBake files are handled manually because the old Spacemacs layer
  ;; is not present in this snapshot.
  (use-package bitbake-ts-mode
    :mode
    (("\\.bb\\'" . bitbake-ts-mode)
     ("\\.bbappend\\'" . bitbake-ts-mode)
     ("\\.bbclass\\'" . bitbake-ts-mode)
     ("\\.inc\\'" . bitbake-ts-mode)
     ("conf/local\\.conf\\'" . bitbake-ts-mode)
     ("conf/bblayers\\.conf\\'" . bitbake-ts-mode)))

  ;; Nix editing stays on eglot+nixd because it is already lightweight and reliable here.
  (defun my/nixd--nix-system ()
    (let* ((arch (cond
                  ((string-match-p "aarch64\\|arm64" system-configuration) "aarch64")
                  ((string-match-p "i686" system-configuration) "i686")
                  (t "x86_64")))
           (os (if (eq system-type 'darwin) "darwin" "linux")))
      (format "%s-%s" arch os)))

  (defun my/nixd-contact (_interactive _project)
    (list "nixd"
          "--nixpkgs-expr"
          (format "import <nixpkgs> { system = \"%s\"; }"
                  (my/nixd--nix-system))
          "--nixos-options-expr" "{}"))

  (defun my/nix-mode-setup ()
    (when (require 'eglot nil t)
      (eglot-ensure))
    (when (fboundp 'company-mode)
      (company-mode 1))
    (setq-local company-idle-delay 0.2
                company-minimum-prefix-length 1)
    (when (boundp 'company-backends)
      (setq-local company-backends '(company-capf)))
    (when (fboundp 'nix-format-before-save)
      (add-hook 'before-save-hook #'nix-format-before-save nil t)))

  (use-package nix-mode
    :mode "\\.nix\\'"
    :config
    (setq nix-indent-function 'nix-indent-line
          nix-nixfmt-bin "nixfmt")
    (add-hook 'nix-mode-hook #'my/nix-mode-setup)
    (with-eval-after-load 'eglot
      (add-to-list 'eglot-server-programs
                   `(nix-mode . ,#'my/nixd-contact))))

  (defvar my/rcirc-server "irc.libera.chat"
    "Primary IRC server for the native rcirc layer.")

  (defvar my/rcirc-port "6697"
    "TLS port for the native rcirc layer.")

  (defvar my/rcirc-nick (or (getenv "RCIRC_NICK") "lvanasse")
    "IRC nick used by rcirc.")

  (defvar my/rcirc-user-name my/rcirc-nick
    "IRC user name used by rcirc.")

  (defvar my/rcirc-full-name user-full-name
    "Full name announced by rcirc.")

  (defvar my/rcirc-channels '("#emacs" "#yocto")
    "Channels to autojoin on Libera Chat.")

  (setq rcirc-default-nick my/rcirc-nick
        rcirc-default-user-name my/rcirc-user-name
        rcirc-default-full-name my/rcirc-full-name
        rcirc-server-alist
        `((,my/rcirc-server
           :encryption tls
           :port ,my/rcirc-port
           :nick ,my/rcirc-nick
           :user-name ,my/rcirc-user-name
           :full-name ,my/rcirc-full-name
           :channels ,my/rcirc-channels)))

  (defconst my/slack-private-config
    (expand-file-name "~/.config/slack/private.el")
    "Local Slack secrets and team registration forms kept out of the repo.")

  (defconst my/spotify-private-config
    (expand-file-name "~/.config/spotify/private.el")
    "Optional local Spotify API credentials kept out of the repo.")

  (defun my/spotify-session-service-name ()
    "Return the current MPRIS service suffix for spotifyd or Spotify.

Prefer the live spotifyd session name because it changes per instance
(`rs.spotifyd.instance...`). Fall back to the official client name."
    (when (featurep 'dbusbind)
      (let* ((names (dbus-list-names :session))
             (spotifyd
              (seq-find
               (lambda (name)
                 (string-prefix-p "rs.spotifyd.instance" name))
               names)))
        (cond
         (spotifyd spotifyd)
         ((member "org.mpris.MediaPlayer2.spotify" names) "spotify")
         (t nil)))))

  (defun my/refresh-spotify-service-name (&rest _args)
    (let ((service (my/spotify-session-service-name)))
      (when service
        (setq spotify-service-name service
              counsel-spotify-service-name service))))

  (with-eval-after-load 'org
    (setq org-directory "~/org")
    (dolist (agenda-file '("calendar.org" "reminders.org"))
      (let ((path (expand-file-name agenda-file org-directory)))
        (unless (member path org-agenda-files)
          (add-to-list 'org-agenda-files path))))
    (setq appt-message-warning-time 15
          appt-display-interval 5
          appt-display-mode-line t)
    (defun my/org-agenda-to-appt ()
      (setq appt-time-msg-list nil)
      (org-agenda-to-appt t))
    (defun my/appt-send-notification (min-to-app new-time msg)
      (if (require 'notifications nil t)
          (notifications-notify
           :title (format "Calendar in %s minute%s" min-to-app (if (= min-to-app 1) "" "s"))
           :body (format "%s at %s" msg new-time)
           :app-name "Emacs")
        (appt-disp-window min-to-app new-time msg)))
    (setq appt-disp-window-function #'my/appt-send-notification)
    (add-hook 'org-agenda-finalize-hook #'my/org-agenda-to-appt)
    (add-hook 'after-init-hook
              (lambda ()
                (my/org-agenda-to-appt)
                (appt-activate 1))))

  (defun my/org-caldav-sync ()
    (interactive)
    (require 'org-caldav)
    (let ((inhibit-read-only t))
      (save-window-excursion
        (org-caldav-sync)))
    (when (fboundp 'my/org-agenda-to-appt)
      (my/org-agenda-to-appt))
    (message "Finished CalDAV sync."))

  (defvar my/org-caldav-auto-sync-interval (* 15 60)
    "How often to auto-sync the calendar, in seconds.")

  (defvar my/org-caldav-auto-sync-timer nil
    "Timer used for background org-caldav sync.")

  (defvar my/org-caldav-sync-in-progress nil
    "Non-nil while a calendar sync is already running.")

  (defun my/org-caldav-sync-safe ()
    (unless my/org-caldav-sync-in-progress
      (let ((my/org-caldav-sync-in-progress t))
        (condition-case err
            (my/org-caldav-sync)
          (error
           (message "org-caldav auto-sync failed: %s"
                    (error-message-string err)))))))

  (defun my/org-caldav-start-auto-sync ()
    (interactive)
    (when (timerp my/org-caldav-auto-sync-timer)
      (cancel-timer my/org-caldav-auto-sync-timer))
    (setq my/org-caldav-auto-sync-timer
          (run-at-time "2 min"
                       my/org-caldav-auto-sync-interval
                       #'my/org-caldav-sync-safe))
    (message "Started org-caldav auto-sync every %s minutes."
             (/ my/org-caldav-auto-sync-interval 60)))

  (defun my/org-caldav-reset-state ()
    (interactive)
    (require 'org-caldav)
    (dolist (calendar-id (delete-dups (cons org-caldav-calendar-id
                                            (mapcar (lambda (cal)
                                                      (plist-get cal :calendar-id))
                                                    org-caldav-calendars))))
      (let ((state-file (org-caldav-sync-state-filename calendar-id)))
        (when (file-exists-p state-file)
          (delete-file state-file))))
    (setq org-caldav-event-list nil
          org-caldav-previous-calendar nil)
    (message "Cleared org-caldav sync state."))

  (defun my/org-caldav-basic-auth-header ()
    (when (and (boundp 'org-caldav-username)
               (boundp 'org-caldav-password)
               org-caldav-username
               org-caldav-password)
      (concat "Basic "
              (base64-encode-string
               (concat org-caldav-username ":" org-caldav-password)
               t))))

  (defun my/org-caldav-inject-basic-auth (orig-fn url &optional request-method request-data extra-headers)
    (if (or (not (stringp url))
            (not (string-prefix-p "https://sync.infomaniak.com/" url))
            (assoc "Authorization" extra-headers))
        (funcall orig-fn url request-method request-data extra-headers)
      (let ((auth (my/org-caldav-basic-auth-header)))
        (funcall orig-fn
                 url
                 request-method
                 request-data
                 (if auth
                     (cons `("Authorization" . ,auth) extra-headers)
                   extra-headers)))))

  (use-package org-caldav
    :after org
    :commands (org-caldav-sync my/org-caldav-sync my/org-caldav-reset-state)
    :init
    (setq org-caldav-url "https://sync.infomaniak.com/calendars/LV04107/"
          org-caldav-calendar-id "a0fe5b9b-1a59-4cbe-8b13-bd262bf0738b"
          org-caldav-inbox "~/org/calendar.org"
          org-caldav-files '("~/org/calendar.org")
          org-icalendar-timezone "America/Toronto"
          org-caldav-sync-changes-to-org 'title-and-timestamp
          org-caldav-delete-org-entries 'never
          org-caldav-delete-calendar-entries 'never
          org-caldav-resume-aborted 'never
          org-caldav-show-sync-results nil
          org-caldav-save-buffers t
          org-caldav-debug-level 2)
    :config
    (let ((password-file (or (getenv "ORG_CALDAV_PASSWORD_FILE")
                             (expand-file-name "~/.config/calendar/infomaniak-caldav-password"))))
      (setq org-caldav-calendars
            `((:calendar-id ,org-caldav-calendar-id
               :inbox ,org-caldav-inbox
               :files ,org-caldav-files)))
      (when (file-readable-p password-file)
        (setq org-caldav-username "LV04107"
              org-caldav-password
              (string-trim
               (with-temp-buffer
                 (insert-file-contents password-file)
                 (buffer-string))))))
  )
  (advice-add 'org-caldav-url-retrieve-synchronously :around
              #'my/org-caldav-inject-basic-auth)
  (add-hook 'after-init-hook #'my/org-caldav-start-auto-sync)
  (spacemacs/set-leader-keys
    "aoS" 'my/org-caldav-sync
    "aec" 'my/mu4e-compose-new
    "aeu" 'mu4e-update-mail-and-index)

  ;; Reuse the existing Maildir + mbsync/msmtp setup from Home Manager.
  (use-package mu4e
    :commands (mu4e mu4e-compose-new mu4e-update-mail-and-index)
    :if (locate-library "mu4e")
    :init
    (setq mail-user-agent 'mu4e-user-agent
          read-mail-command #'mu4e
          mu4e-mu-binary "__MU_BIN__"
          mu4e-maildir "~/mail"
          mu4e-drafts-folder "/ludovic/Drafts"
          mu4e-sent-folder "/ludovic/Sent"
          mu4e-trash-folder "/ludovic/Trash"
          mu4e-refile-folder "/ludovic/Archives"
          mu4e-get-mail-command "__ISYNC_BIN__ -a"
          mu4e-update-interval nil
          mu4e-change-filenames-when-moving t
          mu4e-view-show-images t
          mu4e-compose-format-flowed t
          message-send-mail-function 'message-send-mail-with-sendmail
          sendmail-program "__MSMTP_BIN__"
          message-sendmail-f-is-evil t
          message-sendmail-extra-arguments '("--read-envelope-from")
          mu4e-maildir-shortcuts
          '((:maildir "/ludovic/Index" :key ?i :name "Inbox")
            (:maildir "/ludovic/Promotions" :key ?p :name "Promotions")
            (:maildir "/ludovic/SocialNetworks" :key ?n :name "Social Networks")
            (:maildir "/ludovic/Drafts" :key ?d :name "Drafts")
            (:maildir "/ludovic/Sent" :key ?s :name "Sent")
            (:maildir "/ludovic/Spam" :key ?x :name "Spam")
            (:maildir "/ludovic/Trash" :key ?t :name "Trash")
            (:maildir "/ludovic/Archives" :key ?a :name "Archives"))
          mu4e-bookmarks
          '((:name "Unread messages" :query "flag:unread AND NOT flag:trashed" :key ?u)
            (:name "Today's messages" :query "date:today..now" :key ?t)
            (:name "Last 7 days" :query "date:7d..now" :key ?w)
            (:name "Sent mail" :query "maildir:/ludovic/Sent" :key ?s)))
    :config
    (global-set-key (kbd "C-x m") #'mu4e-compose-new))

  (use-package mu4e-alert
    :after mu4e
    :if (locate-library "mu4e-alert")
    :config
    (setq mu4e-alert-interesting-mail-query my/mu4e-alert-query
          mu4e-alert-style 'notifications)
    (mu4e-alert-enable-notifications)
    (mu4e-alert-enable-mode-line-display))

  ;; Use the native Spacemacs GitHub Copilot layer for chat and completions.
  (setq github-copilot-enable-commit-messages nil)

  (spacemacs|use-package-add-hook copilot-chat
    :pre-config
    (require 'copilot-chat nil t))

  (with-eval-after-load 'copilot
    ;; Newer Copilot language-server builds choke on a null configuration
    ;; payload during workspace/didChangeConfiguration, so always send a real
    ;; object for the GitHub Copilot section.
    (setq copilot-lsp-settings '(:github (:copilot ()))
          copilot-indent-offset-warning-disable t))

  (with-eval-after-load 'copilot-chat
    (let ((copilot-chat-config-dir (expand-file-name "~/.config/copilot-chat/"))
          (copilot-chat-state-dir (expand-file-name "~/.local/state/copilot-chat/")))
      (setq copilot-chat-backend 'curl
            copilot-chat-curl-program "__CURL_BIN__"
            copilot-chat-frontend 'markdown
            copilot-chat-follow t
            copilot-chat-default-model "gpt-4.1"
            copilot-chat-github-token-file
            (expand-file-name "github-token" copilot-chat-config-dir)
            copilot-chat-token-cache
            (expand-file-name "token-cache" copilot-chat-state-dir)
            copilot-chat-models-cache-file
            (expand-file-name "models.json" copilot-chat-state-dir)
            copilot-chat-default-save-dir
            (expand-file-name "chats/" copilot-chat-state-dir))))

  (with-eval-after-load 'slack
    (my/load-private-elisp my/slack-private-config))

  (with-eval-after-load 'spotify
    (my/refresh-spotify-service-name)
    (advice-add 'spotify-dbus-call :before #'my/refresh-spotify-service-name)
    (when (file-readable-p my/spotify-private-config)
      (require 'counsel-spotify nil t)
      (my/load-private-elisp my/spotify-private-config)))

  (with-eval-after-load 'counsel-spotify
    (my/refresh-spotify-service-name)
    (advice-add 'counsel-spotify-call-spotify-via-dbus :before #'my/refresh-spotify-service-name))

  ;; LSP tuning for work languages.
  (with-eval-after-load 'lsp-mode
    (setq lsp-idle-delay 0.2
          lsp-log-io nil
          lsp-enable-on-type-formatting nil
          lsp-headerline-breadcrumb-enable t
          lsp-enable-symbol-highlighting t))

  (with-eval-after-load 'lsp-clangd
    (setq lsp-clients-clangd-args
          '("--background-index"
            "--clang-tidy"
            "--completion-style=detailed"
            "--header-insertion=iwyu")))

  (with-eval-after-load 'lsp-pyright
    (setq lsp-pyright-langserver-command "basedpyright-langserver"
          lsp-pyright-typechecking-mode "basic"))

  (with-eval-after-load 'lsp-yaml
    (setq lsp-yaml-schema-store-enable t
          lsp-yaml-schemas
          '(("https://json.schemastore.org/github-workflow.json"
             . "/.github/workflows/*.yml")
            ("https://json.schemastore.org/github-workflow.json"
             . "/.github/workflows/*.yaml"))))

  ;; Keep Treemacs in sync with the current project/buffer.
  (with-eval-after-load 'treemacs
    (treemacs-follow-mode t)
    (treemacs-filewatch-mode t)
    (treemacs-project-follow-mode t))

  ;; Tabs stay enabled all the time, but prefer Nerd Font icons when the
  ;; installed centaur-tabs snapshot knows about that backend.
  (with-eval-after-load 'centaur-tabs
    (setq centaur-tabs-set-icons t)
    (when (boundp 'centaur-tabs-icon-type)
      (setq centaur-tabs-icon-type 'nerd-icons))
    (global-set-key (kbd "C-x t o") #'centaur-tabs-forward)
    (global-set-key (kbd "C-x t O") #'centaur-tabs-backward))

  ;; Chat tooling stays opt-in and leader-key driven.
  (use-package aidermacs
    :commands
    (aidermacs-transient-menu
     aidermacs-add-current-file
     aidermacs-add-files-in-current-window
     aidermacs-reset-session)
    :init
    (setq aidermacs-backend 'comint)
    :config
    (spacemacs/set-leader-keys
      "aa" 'aidermacs-transient-menu
      "ar" 'aidermacs-reset-session)
    (dolist (mode '(nix-mode python-mode c-mode c++-mode cmake-mode yaml-mode sh-mode bitbake-ts-mode))
      (spacemacs/set-leader-keys-for-major-mode mode
        "aa" 'aidermacs-transient-menu
        "af" 'aidermacs-add-current-file)))
  )
