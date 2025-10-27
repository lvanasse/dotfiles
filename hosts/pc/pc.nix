{
  hostname,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
    # Also offer Sway as an alternative Wayland session
    ../../modules/nixos/desktop/sway.nix
  ];

  # Set hostname
  networking.hostName = hostname;

  # Boot configuration
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        useOSProber = true;
        efiSupport = true;
      };
      efi.canTouchEfiVariables = true;
    };

    # PC-specific hardware configuration
    kernelParams = [
      "acpi_enforce_resources=lax"
    ];
    kernelModules = [
      "coretemp"
      "nct6775"
    ];
    initrd.kernelModules = [ "amdgpu" ];
  };

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      libva-utils
    ];
  };

  # Required for Sunshine (virtual input device)
  hardware.uinput.enable = true;

  # PC-specific networking
  networking = {
    useNetworkd = true;
    interfaces.enp5s0.useDHCP = true;
    networkmanager.dns = "systemd-resolved";

    # Firewall for torrenting
    firewall = {
      enable = true;
      allowedTCPPorts = [
        59793
        47984
        47985
        47986
        47987
        47988
        47989
        47990
        48010
      ];
      # Sunshine/Moonlight streaming + discovery
      allowedUDPPorts = [
        47998
        47999
        48000
        48010
        # Keep existing allowances (harmless, though not required by Sunshine)
        47984
        47985
        47986
        47987
        47988
        47989
        47990
      ];
    };
  };

  # Services
  services = {
    # DNS configuration
    resolved = {
      enable = true;
      dnssec = "false";
      fallbackDns = [
        "1.1.1.1"
        "9.9.9.9"
      ];
      extraConfig = ''
        Cache=no-negative                  # avoid long NXDOMAIN waits
        TrustAnchor=false                  # strips the "trust-ad" bit
      '';
    };

    tailscale.enable = false;

    # VPN configuration
    openvpn.servers = {
      lux = {
        config = ''
          config /home/ludovic/Downloads/lux_mtl-config_most-clients.ovpn
        '';
        autoStart = false;
      };
    };

    # PC-specific Flatpak configuration
    flatpak = {
      remotes = lib.mkOptionDefault [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
        {
          name = "woblight";
          location = "https://woblight.gitlab.io/flatpak-repo";
        }
      ];
      packages = [
        {
          appId = "io.gitlab.woblight.GitAddonsManager//master";
          origin = "woblight";
        }
      ];
    };
  };

  # Programs
  programs = {
    coolercontrol.enable = true;
    steam = {
      enable = true;
      gamescopeSession.enable = true;
    };
    gamemode.enable = true;
  };

  # qBittorrent service
  systemd.user.services.qbittorrent-tray = {
    description = "qBittorrent (GUI, tray only)";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.qbittorrent}/bin/qbittorrent --no-splash";
      Restart = "on-abort";
    };
  };

  # Provide CAP_SYS_ADMIN to Sunshine via a persistent wrapper so KMS capture
  # works even when wlroots export-dmabuf is unavailable (e.g., Plasma Wayland).
  # This avoids manual `setcap` on the immutable Nix store path.
  security.wrappers.sunshine = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+ep";
    source = "${pkgs.sunshine}/bin/sunshine";
  };

  # Sunshine user service (GameStream host)
  # Notes:
  # - Run only when a Wayland socket exists to avoid KMS fallback which
  #   requires CAP_SYS_ADMIN (not available in user services).
  # - First run: open https://localhost:47990 to finish setup.
  systemd.user.services.sunshine = {
    description = "Sunshine GameStream host";
    partOf = [ "graphical-session.target" ];
    wantedBy = [
      "graphical-session.target"
      "sway-session.target"
    ];
    after = [
      "graphical-session.target"
      "sway-session.target"
    ];
    serviceConfig = {
      # Wait for a Wayland socket to exist to avoid KMS fallback
      ExecStartPre = ''${pkgs.bash}/bin/bash -lc "for i in $(seq 1 30); do if [ -S \"$XDG_RUNTIME_DIR/wayland-1\" ] || [ -S \"$XDG_RUNTIME_DIR/wayland-0\" ]; then exit 0; fi; sleep 1; done; echo \"No Wayland socket found in $XDG_RUNTIME_DIR (wayland-1/0)\" >&2; exit 1" '';
      # Use the wrapper with CAP_SYS_ADMIN so Sunshine can use KMS capture
      # when Wayland export-dmabuf is unavailable.
      ExecStart = "/run/wrappers/bin/sunshine";
      Restart = "on-failure";
      RestartSec = "5s";
      # Provide correct runtime dir for Wayland socket lookup
      # Also provide a robust PATH so Sunshine can spawn helpers (setsid, steam)
      # referenced by default app entries.
      Environment = [
        "XDG_RUNTIME_DIR=%t"
        "PATH=/run/wrappers/bin:/run/current-system/sw/bin"
        "LIBVA_DRIVER_NAME=radeonsi"
      ];
    };
  };

  # PC-specific packages
  environment.systemPackages = with pkgs; [
    openvpn3
    fanctl
    nvtopPackages.full
    coolercontrol.coolercontrold
    coolercontrol.coolercontrol-liqctld
    coolercontrol.coolercontrol-gui
    coolercontrol.coolercontrol-ui-data
    mesa
    gmp
    libmpc
    mpfr
    isl
    sunshine
  ];

  # Relax hidraw permissions for controller passthrough (e.g., DualSense)
  # Sunshine reads/writes hidraw for rumble/LEDs; grant group access.
  services.udev.extraRules = ''
    # Allow rumble/LED control and direct HID access for controllers
    SUBSYSTEM=="hidraw", KERNEL=="hidraw*", MODE="0660", GROUP="input"
    # Allow reading input event devices for gamepad passthrough
    KERNEL=="event*", SUBSYSTEM=="input", MODE="0660", GROUP="input"
  '';

  # Deploy SSH keys via agenix (system-level) using encrypted files from the
  # private secrets repository. Decrypts using host SSH keys by default.
  age.secrets = {
    "ssh-id_ed25519_personal" = {
      file = "${inputs.secrets}/ssh/id_ed25519_personal.age";
      path = "/home/ludovic/.ssh/id_ed25519_personal";
      mode = "0600";
      owner = "ludovic";
      group = "users";
    };
    "ssh-id_ed25519_work" = {
      file = "${inputs.secrets}/ssh/id_ed25519_work.age";
      path = "/home/ludovic/.ssh/id_ed25519_work";
      mode = "0600";
      owner = "ludovic";
      group = "users";
    };
  };

  # Ensure ssh-agent for convenience
  programs.ssh.startAgent = true;

  # Passwordless auth using the single public key
  users.users.ludovic.openssh.authorizedKeys.keys = [
    (builtins.readFile "${inputs.secrets}/keys/id_ed25519_personal.pub")
    (builtins.readFile "${inputs.secrets}/keys/id_ed25519_work.pub")
  ];
}
