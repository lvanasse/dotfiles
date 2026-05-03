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
     (auto-completion :variables auto-completion-enable-snippets-in-popup t)
     syntax-checking
     ivy
     lsp
     (treemacs :variables treemacs-use-follow-mode t)
     c-c++
     cmake
     markdown
     python
     yaml
     (shell :variables shell-default-shell 'vterm)
     shell-scripts
   )
   dotspacemacs-additional-packages '(gruvbox-theme vterm clipetty copilot-chat aidermacs bitbake-ts-mode nix-mode org-caldav)
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
  (when (and (not (display-graphic-p))
             (require 'clipetty nil t))
    (global-clipetty-mode 1))

  ;; Load mu4e from the Nix store so Spacemacs can use the Home Manager
  ;; mail stack without relying on ELPA packaging.
  (dolist (mu4e-path
           (delete-dups
            (append
             (file-expand-wildcards "/nix/store/*-mu-*/share/emacs/site-lisp/mu4e")
             (file-expand-wildcards "/nix/store/*-mu-*/share/emacs/site-lisp/mu")
             (file-expand-wildcards "/nix/store/*-mu-*/share/emacs/site-lisp")
             '("__MU_SITE_LISP_MU4E__"
               "__MU_SITE_LISP_MU__"
               "__MU_SITE_LISP__"))))
    (when (file-directory-p mu4e-path)
      (add-to-list 'load-path mu4e-path)))

  (defun my/mu4e ()
    (interactive)
    (unless (require 'mu4e nil t)
      (user-error "mu4e is not available; run Home Manager switch and restart Emacs"))
    (call-interactively #'mu4e))

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

  (with-eval-after-load 'org
    (setq org-directory "~/org")
    (let ((calendar-file (expand-file-name "calendar.org" org-directory)))
      (unless (member calendar-file org-agenda-files)
        (add-to-list 'org-agenda-files calendar-file)))
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

  (defun my/org-caldav-keep-repeater-p (date)
    "Keep RRULE-derived repeaters only for current-year-or-newer events."
    (let* ((parts (mapcar #'string-to-number (split-string date)))
           (year (nth 2 parts))
           (current-year (string-to-number (format-time-string "%Y"))))
      (>= year current-year)))

  (defun my/org-caldav-strip-old-repeaters ()
    "Remove Org repeaters from imported calendar entries older than the current year."
    (interactive)
    (let* ((calendar-file (expand-file-name "~/org/calendar.org"))
           (current-year (string-to-number (format-time-string "%Y")))
           (changed 0))
      (when (file-readable-p calendar-file)
        (with-current-buffer (find-file-noselect calendar-file)
          (save-excursion
            (goto-char (point-min))
            (while (not (eobp))
              (let ((line (buffer-substring-no-properties
                           (line-beginning-position)
                           (line-end-position))))
                (when (and (string-match "^<\\([0-9]\\{4\\}\\)-" line)
                           (< (string-to-number (match-string 1 line)) current-year)
                           (string-match " \\(?:\\.\\+\\|\\+\\+\\|\\+\\)[0-9]+[hdwmy]>" line))
                  (setq line
                        (replace-regexp-in-string
                         " \\(?:\\.\\+\\|\\+\\+\\|\\+\\)[0-9]+[hdwmy]>"
                         ">"
                         line))
                  (delete-region (line-beginning-position) (line-end-position))
                  (insert line)
                  (setq changed (1+ changed))))
              (forward-line 1)))
          (when (> changed 0)
            (save-buffer))))
      (when (called-interactively-p 'interactive)
        (message "Removed %s old calendar repeaters." changed))
      changed))

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
  (advice-add 'org-caldav-convert-to-org-time :around
              (lambda (orig-fn date &optional time rrule-props)
                (if (and rrule-props (not (my/org-caldav-keep-repeater-p date)))
                    (funcall orig-fn date time nil)
                  (funcall orig-fn date time rrule-props))))
  (advice-add 'org-caldav-sync :after
              (lambda (&rest _)
                (my/org-caldav-strip-old-repeaters)
                (when (fboundp 'my/org-agenda-to-appt)
                  (my/org-agenda-to-appt))))
  (add-hook 'after-init-hook #'my/org-caldav-start-auto-sync)
  (spacemacs/set-leader-keys
    "ac" 'my/org-caldav-sync
    "am" 'my/mu4e
    "aM" 'my/mu4e-compose-new)

  ;; Reuse the existing Maildir + mbsync/msmtp setup from Home Manager.
  (use-package mu4e
    :commands (mu4e mu4e-compose-new mu4e-update-mail-and-index)
    :if (locate-library "mu4e")
    :init
    (setq mail-user-agent 'mu4e-user-agent
          read-mail-command #'mu4e
          mu4e-maildir "~/mail"
          mu4e-drafts-folder "/ludovic/Drafts"
          mu4e-sent-folder "/ludovic/Sent messages"
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
            (:maildir "/ludovic/Sent messages" :key ?s :name "Sent messages")
            (:maildir "/ludovic/Spam" :key ?x :name "Spam")
            (:maildir "/ludovic/Trash" :key ?t :name "Trash")
            (:maildir "/ludovic/Archives" :key ?a :name "Archives"))
          mu4e-bookmarks
          '((:name "Unread messages" :query "flag:unread AND NOT flag:trashed" :key ?u)
            (:name "Today's messages" :query "date:today..now" :key ?t)
            (:name "Last 7 days" :query "date:7d..now" :key ?w)
            (:name "Sent mail" :query "maildir:/ludovic/Sent messages" :key ?s)))
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

  (use-package copilot-chat
    :commands
    (copilot-chat-add-current-buffer
     copilot-chat-custom-prompt-mini-buffer
     copilot-chat-custom-prompt-selection
     copilot-chat-del-current-buffer
     copilot-chat-display
     copilot-chat-explain
     copilot-chat-list
     copilot-chat-review
     copilot-chat-review-whole-buffer)
    :init
    (setq copilot-chat-backend 'curl
          copilot-chat-curl-program "__CURL_BIN__"
          copilot-chat-frontend 'org
          copilot-chat-follow t)
    :config
    (spacemacs/set-leader-keys
      "acc" 'copilot-chat-display
      "acp" 'copilot-chat-custom-prompt-mini-buffer
      "acl" 'copilot-chat-list)
    (dolist (mode '(nix-mode python-mode c-mode c++-mode cmake-mode yaml-mode sh-mode))
      (spacemacs/set-leader-keys-for-major-mode mode
        "cc" 'copilot-chat-display
        "ca" 'copilot-chat-add-current-buffer
        "cd" 'copilot-chat-del-current-buffer
        "ce" 'copilot-chat-explain
        "cp" 'copilot-chat-custom-prompt-selection
        "cr" 'copilot-chat-review
        "cR" 'copilot-chat-review-whole-buffer))))
