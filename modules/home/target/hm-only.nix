{ ... }:
{
  flake.modules.homeManager."target.config.hm-only" =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      username = config.home.username;
      nohm = pkgs.writeShellScriptBin "nohm" ''
        set -euo pipefail

        NOHM_VERBOSE="''${NOHM_VERBOSE:-0}"
        log_verbose() {
          if [ "''${NOHM_VERBOSE}" = "1" ]; then
            echo "$@" >&2
          fi
        }
        log_cmd() {
          local label="$1"
          shift
          printf '%s %s\n' "$label" "$*" >&2
        }

        if [ $# -lt 1 ]; then
          echo "Usage: nohm <host>|auth [--target-host <user@ip>] [-- <extra nh os args>]" >&2
          exit 1
        fi

        host="$1"
        shift

        target_host=""
        pass_args=()
        while [ $# -gt 0 ]; do
          case "$1" in
            --target-host)
              if [ $# -lt 2 ]; then
                echo "Missing value for --target-host" >&2
                exit 1
              fi
              target_host="$2"
              pass_args+=("$1" "$2")
              shift 2
              ;;
            --)
              pass_args+=("$@")
              break
              ;;
            *)
              pass_args+=("$1")
              shift
              ;;
          esac
        done

        flake_dir="$HOME/Code/personal/dotfiles"
        if [ -n "''${NH_FLAKE-}" ]; then
          flake_dir="''${NH_FLAKE}"
        fi
        nix_switch_script="''${flake_dir}/scripts/nix-switch.sh"
        setup_sway_auth_script="''${flake_dir}/scripts/setup-sway-auth.sh"

        if [ "''${host}" = "auth" ]; then
          exec bash "''${setup_sway_auth_script}"
        fi

        nh_bin="${pkgs.nh}/bin/nh"
        hm_bin="${pkgs.home-manager}/bin/home-manager"
        git_bin="${pkgs.git}/bin/git"
        nproc_bin="${pkgs.coreutils}/bin/nproc"

        reserve_cores="''${MACHINE_RESERVED_CORES:-''${NOHM_RESERVED_CORES:-1}}"
        case "''${reserve_cores}" in
          ""|*[!0-9]*) reserve_cores=1 ;;
        esac

        build_cores="''${NOHM_BUILD_CORES:-1}"
        case "''${build_cores}" in
          ""|*[!0-9]*) build_cores=1 ;;
        esac

        total_cores="$("$nproc_bin")"
        case "''${total_cores}" in
          ""|*[!0-9]*) total_cores=1 ;;
        esac

        max_jobs=$(( total_cores - reserve_cores ))
        if [ "''${max_jobs}" -lt 1 ]; then
          max_jobs=1
        fi

        nix_config=$(printf 'max-jobs = %s\ncores = %s' "''${max_jobs}" "''${build_cores}")
        if [ -n "''${NIX_CONFIG-}" ]; then
          nix_config="''${nix_config}
''${NIX_CONFIG}"
        fi
        log_verbose "[cfg] Nix: leaving ''${reserve_cores} machine core(s) free; max-jobs=''${max_jobs}; cores=''${build_cores}"

        is_home_manager_only_target() {
          case "''${host}" in
            hm-only|work-laptop|steamdeck) return 0 ;;
            *) return 1 ;;
          esac
        }

        if is_home_manager_only_target; then
          if [ -n "''${target_host}" ]; then
            echo "nohm: --target-host is not supported for Home Manager-only targets; run nohm on that machine." >&2
            exit 1
          fi
          exec bash "''${nix_switch_script}" "''${host}"
        fi

        if [ "''${NOHM_AUTO_INTENT_TO_ADD:-1}" = "1" ] \
          && "$git_bin" -C "''${flake_dir}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          did_ita=""
          while IFS= read -r -d $'\0' path; do
            if [ -z "''${did_ita}" ]; then
              log_verbose "[pre] Git: marking untracked files as intent-to-add for flake evaluation"
              did_ita="1"
            fi
            "$git_bin" -C "''${flake_dir}" add -N -- "$path"
          done < <("$git_bin" -C "''${flake_dir}" ls-files --others --exclude-standard -z)
        fi

        bext="''${HM_BACKUP_EXT:-hm-$(date +%Y%m%d-%H%M%S)}"
        if [ -n "''${target_host}" ]; then
          log_verbose "[1/2] Home Manager: skipped explicit switch (applied by NixOS activation on remote target)"
        else
          log_cmd "[1/2]" "home-manager switch --flake ''${flake_dir}#${username}@''${host} -b ''${bext}"
          NIX_CONFIG="''${nix_config}" "$hm_bin" switch --flake "''${flake_dir}#${username}@''${host}" -b "''${bext}"
        fi

        log_cmd "[2/2]" "nh os switch -H ''${host} ''${pass_args[*]}"
        NH_FLAKE="''${flake_dir}" NIX_CONFIG="''${nix_config}" "$nh_bin" os switch -H "''${host}" "''${pass_args[@]}"
      '';
    in
    let
  # Wrap sway with nixGL for proper OpenGL/Vulkan support on non-NixOS
  swayWrapped = pkgs.writeShellScriptBin "sway" ''
    export PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:$HOME/.local/state/nix/profile/bin:$PATH"
    export XDG_DATA_DIRS="$HOME/.nix-profile/share:$HOME/.local/state/nix/profile/share:/nix/var/nix/profiles/default/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    export XDG_CURRENT_DESKTOP=sway
    export XDG_SESSION_DESKTOP=sway
    export XDG_SESSION_TYPE=wayland
    export GTK_USE_PORTAL=1
    export QT_QPA_PLATFORM=wayland
    export SDL_VIDEODRIVER=wayland
    export MOZ_ENABLE_WAYLAND=1
    export MOZ_GTK_TITLEBAR_DECORATION=system
    export ELECTRON_OZONE_PLATFORM_HINT=wayland
    export SLACK_DISABLE_GPU=1
    exec ${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${config.wayland.windowManager.sway.package}/bin/sway "$@"
  '';
  homeDir = config.home.homeDirectory;
  jiraCfgAge = "${inputs.secrets}/jira/config.yml.age";
  jiraTokenAge = "${inputs.secrets}/jira/api_token.age";
  infomaniakMailAge = "${inputs.secrets}/email/mail@ludovicvanasse.com-infomaniak.age";
  infomaniakCaldavAge = "${inputs.secrets}/calendar/infomaniak-caldav-password.age";
  slackPrivateElAge = "${inputs.secrets}/emacs/slack-private.el.age";
  spotifyPrivateElAge = "${inputs.secrets}/emacs/spotify-private.el.age";
  liberaAuthinfoAge = "${inputs.secrets}/irc/authinfo.age";
  hasJiraCfg = builtins.pathExists jiraCfgAge;
  hasJiraToken = builtins.pathExists jiraTokenAge;
  hasInfomaniakMail = builtins.pathExists infomaniakMailAge;
  hasInfomaniakCaldav = builtins.pathExists infomaniakCaldavAge;
  hasSlackPrivateEl = builtins.pathExists slackPrivateElAge;
  hasSpotifyPrivateEl = builtins.pathExists spotifyPrivateElAge;
  hasLiberaAuthinfo = builtins.pathExists liberaAuthinfoAge;
in
{
  # Host-specific overrides for the Home Manager-only configuration go here.
  # Install fonts for non-NixOS systems
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    nixgl.nixGLIntel # For wrapping GL applications
    fd
    ripgrep
    dtc
    picocom
    poetry
    unstable.spotatui
    nohm
  ];

  # Symlink tcl & tk data under a common parent so PyInstaller can find both
  # (Nix splits them into separate store paths, which breaks PyInstaller's path derivation)
  home.file.".local/share/tcltk/lib/${pkgs.tcl.libPrefix}".source = "${pkgs.tcl}/lib/${pkgs.tcl.libPrefix}";
  home.file.".local/share/tcltk/lib/${pkgs.tk.libPrefix}".source = "${pkgs.tk}/lib/${pkgs.tk.libPrefix}";

  home.sessionVariables = {
    EDITOR = lib.mkDefault "vim";
    VISUAL = lib.mkDefault "vim";
    POETRY_VIRTUALENVS_OPTIONS_SYSTEM_SITE_PACKAGES = "true";
    TCL_LIBRARY = "${homeDir}/.local/share/tcltk/lib/${pkgs.tcl.libPrefix}";
    TK_LIBRARY = "${homeDir}/.local/share/tcltk/lib/${pkgs.tk.libPrefix}";
    XDG_DATA_DIRS = "${homeDir}/.nix-profile/share:${homeDir}/.local/state/nix/profile/share:/nix/var/nix/profiles/default/share:/usr/local/share:/usr/share";
    # Slack/Electron screenshare can freeze on some non-NixOS GPU stacks.
    # Wrapper in programs/slack.nix reads this to disable GPU acceleration.
    SLACK_DISABLE_GPU = "1";
  };

  # Decrypt user secrets for hm-only via agenix (if present in secrets repo).
  age.identityPaths = [
    "${homeDir}/.ssh/id_ed25519_personal"
    "${homeDir}/.ssh/id_ed25519_work"
  ];

  age.secrets =
    (lib.optionalAttrs hasJiraCfg {
      "jira-config" = {
        file = jiraCfgAge;
        path = "${homeDir}/.config/.jira/.config.yml";
        mode = "0600";
      };
    })
    // (lib.optionalAttrs hasJiraToken {
      "jira-api-token" = {
        file = jiraTokenAge;
        path = "${homeDir}/.config/.jira/JIRA_API_TOKEN";
        mode = "0600";
      };
    })
    // (lib.optionalAttrs hasInfomaniakMail {
      "infomaniak-mail-password" = {
        file = infomaniakMailAge;
        path = "${homeDir}/.config/mail/infomaniak-password";
        mode = "0600";
      };
    })
    // (lib.optionalAttrs hasInfomaniakCaldav {
      "infomaniak-caldav-password" = {
        file = infomaniakCaldavAge;
        path = "${homeDir}/.config/calendar/infomaniak-caldav-password";
        mode = "0600";
      };
    })
    // (lib.optionalAttrs hasSlackPrivateEl {
      "emacs-slack-private-el" = {
        file = slackPrivateElAge;
        path = "${homeDir}/.config/slack/private.el";
        mode = "0600";
      };
    })
    // (lib.optionalAttrs hasSpotifyPrivateEl {
      "emacs-spotify-private-el" = {
        file = spotifyPrivateElAge;
        path = "${homeDir}/.config/spotify/private.el";
        mode = "0600";
      };
    })
    // (lib.optionalAttrs hasLiberaAuthinfo {
      "libera-authinfo" = {
        file = liberaAuthinfoAge;
        path = "${homeDir}/.authinfo";
        mode = "0600";
      };
    });

  # Use snap-friendly GTK theming on hm-only to avoid snap warnings
  gtk.theme = lib.mkForce {
    name = "Adwaita-dark";
    package = pkgs.gnome-themes-extra;
  };
  gtk.iconTheme = lib.mkForce {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
  };
  gtk.cursorTheme = lib.mkForce {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
  };
  dconf.settings."org/gnome/desktop/interface".gtk-theme = lib.mkForce "Adwaita-dark";
  dconf.settings."org/gnome/desktop/interface".icon-theme = lib.mkForce "Adwaita";
  dconf.settings."org/gnome/desktop/interface".cursor-theme = lib.mkForce "Adwaita";

  # Wrapper for Google Chrome on Wayland to enable PipeWire screen sharing.
  home.file.".local/bin/google-chrome" = {
    executable = true;
    text = ''
      #!/bin/sh
      CHROME_BIN="/usr/bin/google-chrome"
      if [ -x /usr/bin/google-chrome-stable ]; then
        CHROME_BIN="/usr/bin/google-chrome-stable"
      fi
      if [ ! -x "$CHROME_BIN" ]; then
        echo "google-chrome not found in /usr/bin" >&2
        exit 127
      fi
      if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
        exec "$CHROME_BIN" \
          --ozone-platform=wayland \
          --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer \
          "$@"
      else
        exec "$CHROME_BIN" "$@"
      fi
    '';
  };

  home.file.".local/bin/setup-sway-auth" = {
    executable = true;
    text = ''
      #!/bin/sh
      exec bash "$HOME/Code/personal/dotfiles/scripts/setup-sway-auth.sh" "$@"
    '';
  };

  # Provide a PAM service file for swaylock on non-NixOS systems.
  # The nix-switch script will install this into /etc/pam.d/swaylock.
  home.file.".local/share/pam/swaylock".text = ''
    #%PAM-1.0
    auth      required pam_unix.so nullok try_first_pass
    account   required pam_unix.so
    password  required pam_unix.so
    session   required pam_unix.so
  '';

  # Electron apps need --no-sandbox because the SUID helper can't be set in the Nix store.
  home.file.".local/bin/discord" = {
    executable = true;
    text = ''
      #!/bin/sh
      export ELECTRON_NO_SANDBOX=1
      exec ${pkgs.discord}/bin/discord --disable-setuid-sandbox --no-sandbox "$@"
    '';
  };

  home.file.".local/bin/vesktop" = {
    executable = true;
    text = ''
      #!/bin/sh
      export ELECTRON_NO_SANDBOX=1
      exec ${pkgs.vesktop}/bin/vesktop --disable-setuid-sandbox --no-sandbox "$@"
    '';
  };

  home.file.".local/bin/bitwarden" = {
    executable = true;
    text = ''
      #!/bin/sh
      export ELECTRON_NO_SANDBOX=1
      export CHROME_DESKTOP=bitwarden.desktop
      exec ${pkgs.bitwarden-desktop}/bin/bitwarden --disable-setuid-sandbox --no-sandbox "$@"
    '';
  };

  home.file.".local/bin/google-chrome-stable" = {
    executable = true;
    text = ''
      #!/bin/sh
      exec "$HOME/.local/bin/google-chrome" "$@"
    '';
  };

  # Override global Firefox defaults for hm-only: use Chrome as default browser.
  xdg.mimeApps.defaultApplications = {
    "text/html" = lib.mkForce [ "google-chrome.desktop" ];
    "x-scheme-handler/http" = lib.mkForce [ "google-chrome.desktop" ];
    "x-scheme-handler/https" = lib.mkForce [ "google-chrome.desktop" ];
    "x-scheme-handler/about" = lib.mkForce [ "google-chrome.desktop" ];
    "x-scheme-handler/unknown" = lib.mkForce [ "google-chrome.desktop" ];
  };

  xdg.desktopEntries.bitwarden = {
    name = "Bitwarden";
    comment = "Secure and free password manager for all of your devices";
    exec = "${config.home.homeDirectory}/.local/bin/bitwarden %U";
    icon = "bitwarden";
    type = "Application";
    startupNotify = true;
    categories = [ "Utility" ];
    mimeType = [ "x-scheme-handler/bitwarden" ];
  };

  # Wrap wezterm with nixGL for proper OpenGL support on non-NixOS
  programs.wezterm.package = pkgs.writeShellScriptBin "wezterm" ''
    exec ${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${pkgs.wezterm}/bin/wezterm "$@"
  '';
  # Wrapper package doesn't include profile.d/wezterm.sh
  programs.wezterm.enableBashIntegration = false;

  # Use wezterm as the terminal in sway (with full paths for non-NixOS)
  wayland.windowManager.sway.config = {
    terminal = lib.mkForce "${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${pkgs.wezterm}/bin/wezterm";
  };

  # Override the sway desktop entry to use nixGL wrapper
  home.file.".local/share/wayland-sessions/sway.desktop" = lib.mkForce {
    text = ''
      [Desktop Entry]
      Name=Sway
      Comment=Wayland compositor
      Exec=${swayWrapped}/bin/sway
      TryExec=${swayWrapped}/bin/sway
      Type=Application
      DesktopNames=sway
      X-GDM-SessionRegister=true
    '';
  };

  services.kanshi = {
    enable = true;
    systemdTarget = "sway-session.target";
    settings = [
      {
        profile = {
          name = "desk";
          outputs = [
            {
              criteria = "eDP-1";
              mode = "1920x1200@60.001Hz";
              position = "0,1080";
            }
            {
              criteria = "DP-1";
              mode = "1920x1080@60.000Hz";
              position = "1920,0";
            }
            {
              criteria = "HDMI-A-1";
              mode = "1920x1080@60.000Hz";
              position = "0,0";
            }
          ];
        };
      }
      {
        # Fallback when HDMI is missing right after resume/hotplug.
        profile = {
          name = "desk-no-hdmi";
          outputs = [
            {
              criteria = "eDP-1";
              mode = "1920x1200@60.001Hz";
              position = "0,0";
            }
            {
              criteria = "DP-1";
              mode = "1920x1080@60.000Hz";
              position = "1920,0";
            }
          ];
        };
      }
      {
        profile = {
          name = "projector-mirror";
          outputs = [
            {
              criteria = "eDP-1";
              mode = "1920x1080@60.001Hz";
              position = "0,0";
            }
            {
              criteria = "HDMI-A-1";
              mode = "1920x1080@60.000Hz";
              position = "0,0";
            }
          ];
        };
      }
      {
        profile = {
          name = "mobile";
          outputs = [
            {
              criteria = "eDP-1";
              mode = "1920x1200@60.001Hz";
              position = "0,0";
            }
          ];
        };
      }
    ];
  };
    };
}
