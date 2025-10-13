# Development tools and environment
{ config, pkgs, ... }:
{
  programs.emacs = {
    enable = true;
    package = pkgs.emacs;
    extraPackages = epkgs: [
      epkgs.gruvbox-theme
      epkgs.use-package
      epkgs.evil
      epkgs.general
      epkgs.which-key
    ];
  };

  # Minimal Emacs config: gruvbox-dark-hard, Evil, which-key, Spacemacs-like leader
  # Write Emacs config to both XDG and legacy paths so Emacs picks it up regardless of version/build
  home.file.".config/emacs/init.el".text = ''
    ;; UI minimalism
    (when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
    (when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
    (when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
    (setq inhibit-startup-screen t)

    ;; Use packages installed by Nix; don't auto-install from ELPA
    (setq use-package-always-ensure nil)

    ;; Ensure use-package macro is available before using it
    (require 'use-package)

    ;; Theme: Gruvbox dark hard (closest to "gruvbox-dark-harder")
    (load-theme 'gruvbox-dark-hard t)

    ;; which-key for discoverability
    (use-package which-key
      :config
      (which-key-mode 1)
      (setq which-key-idle-delay 0.25))

    ;; Vim keybindings via Evil
    (use-package evil
      :init
      (setq evil-want-keybinding nil)
      :config
      (evil-mode 1))

    ;; Spacemacs-like leader key using general.el
    (use-package general
      :config
      (general-evil-setup t)
      (general-create-definer my/leader
        :states '(normal visual emacs)
        :keymaps 'override
        :prefix "SPC"
        :global-prefix "C-SPC")

      ;; Minimal leader map (extend as you go)
      (my/leader
        "SPC" '(execute-extended-command :which-key "M-x")
        "f"   '(:ignore t :which-key "files")
        "ff"  '(find-file :which-key "find file")
        "fs"  '(save-buffer :which-key "save file")

        "b"   '(:ignore t :which-key "buffers")
        "bb"  '(switch-to-buffer :which-key "switch buffer")
        "bd"  '(kill-this-buffer :which-key "kill buffer")

        "w"   '(:ignore t :which-key "windows")
        "wv"  '(split-window-right :which-key "vsplit")
        "ws"  '(split-window-below :which-key "hsplit")
        "wd"  '(delete-window :which-key "delete window")

        "p"   '(:ignore t :which-key "project")
        "pp"  '(project-switch-project :which-key "switch project")
        "pf"  '(project-find-file :which-key "find file (project)")))
  '';

  home.file.".emacs.d/init.el".text = ''
    ;; Load XDG config; keep this file as a thin wrapper to avoid divergence
    (let* ((xdg (or (getenv "XDG_CONFIG_HOME") (expand-file-name "~/.config")))
           (xdg-init (expand-file-name "emacs/init.el" xdg)))
      (load xdg-init nil 'nomessage))
  '';

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "${config.home.homeDirectory}/Code/personal/dotfiles";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.java = {
    enable = true;
    package = pkgs.openjdk21; # Full JDK instead of minimal JRE
  };
}
