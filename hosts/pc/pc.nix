{
  hostname,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
    # Enable Hyprland on PC only (keep KDE available too)
    ../../modules/nixos/desktop/hyprland.nix
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
      allowedTCPPorts = [ 59793 ];
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
  ];
}
