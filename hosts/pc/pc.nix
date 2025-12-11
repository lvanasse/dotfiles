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
      trustedInterfaces = [ "tailscale0" ];
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

    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      openFirewall = true;
    };

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
    flatpak =
      let
        runtimeCa = "/etc/ssl/certs/ca-bundle.crt";
      in
      {
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
        overrides = {
          "io.gitlab.woblight.GitAddonsManager".Environment = {
            CURL_CA_BUNDLE = runtimeCa;
            GIT_SSL_CAINFO = runtimeCa;
            NIX_SSL_CERT_FILE = runtimeCa;
            SSL_CERT_FILE = runtimeCa;
          };
        };
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

  # PC-specific packages
  environment.systemPackages = with pkgs; [
    openvpn3
    fanctl
    nvtopPackages.full
    coolercontrol.coolercontrold
    coolercontrol.coolercontrol-gui
    coolercontrol.coolercontrol-ui-data
    mesa
    gmp
    libmpc
    mpfr
    isl
  ];

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

  # gnome-keyring already starts gcr-ssh-agent; disable the legacy ssh-agent to avoid conflicts.
  programs.ssh.startAgent = lib.mkForce false;

  # Passwordless auth using the single public key
  users.users.ludovic.openssh.authorizedKeys.keys = [
    (builtins.readFile "${inputs.secrets}/keys/id_ed25519_personal.pub")
    (builtins.readFile "${inputs.secrets}/keys/id_ed25519_work.pub")
  ];
}
