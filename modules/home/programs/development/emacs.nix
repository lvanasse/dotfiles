{ inputs, ... }:
{
  flake.modules.homeManager."programs.development.emacs" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.emacs = {
        enable = true;
        package = pkgs.emacs-unstable;
        extraPackages =
          epkgs:
          with epkgs; [
            gruvbox-theme
            vterm
            clipetty
            copilot-chat
            aidermacs
            bitbake-ts-mode
            nix-mode
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

      home.file.".spacemacs".text = ''
        (defun dotspacemacs/layers ()
          (setq-default
           dotspacemacs-distribution 'spacemacs
           dotspacemacs-enable-lazy-installation 'unused
           dotspacemacs-ask-for-lazy-installation t
           dotspacemacs-install-packages 'used-only
           dotspacemacs-configuration-layers '(
             better-defaults
             git
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
           dotspacemacs-additional-packages '(gruvbox-theme vterm clipetty copilot-chat aidermacs bitbake-ts-mode nix-mode)
           dotspacemacs-excluded-packages '(forge mu4e mu4e-alert)))

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
                  (format "import <nixpkgs> { system = \\\"%s\\\"; }"
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
                  copilot-chat-curl-program "${pkgs.curl}/bin/curl"
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
      '';

      home.file.".emacs.d" = {
        source = inputs.spacemacs;
        recursive = true;
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
