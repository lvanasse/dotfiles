{
  inputs,
  hostname,
  username,
  overlays,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common/system.nix
    ../../modules/common/users.nix
    ../../modules/common/de.nix
    ../../modules/common/gaming.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.efiSupport = true;

  boot.loader.efi.canTouchEfiVariables = true;

  # Fan control
  boot.kernelParams = [
    "acpi_enforce_resources=lax"
  ];
  boot.kernelModules = [
    "coretemp"
    "nct6775"
  ];

  programs.coolercontrol.enable = true;

  services.openvpn.servers = {
    lux = {
      config = ''
        config /home/ludovic/Downloads/lux_mtl-config_most-clients.ovpn
      '';
      autoStart = false;
    };
  };

  services.tailscale.enable = false;

  networking.useNetworkd = true;
  networking.interfaces.enp5s0.useDHCP = true;

  # Specifically for MAM private tracker
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 59793 ];
  };

  # Fix DNS latency issues
  services.resolved = {
    enable = true;
    dnssec = "false";
    fallbackDns = [
      "1.1.1.1"
      "9.9.9.9"
    ];
    extraConfig = ''
      Cache=no-negative                  # avoid long NXDOMAIN waits
      TrustAnchor=false                  # strips the “trust-ad” bit
    '';
  };
  networking.networkmanager.dns = "systemd-resolved";

  boot.initrd.kernelModules = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.graphics.extraPackages = with pkgs; [
    mesa
    libva-utils
  ];

  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;

  systemd.user.services.qbittorrent-tray = {
    description = "qBittorrent (GUI, tray only)";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.qbittorrent}/bin/qbittorrent --no-splash";
      Restart = "on-abort";
    };
  };

  services.flatpak = {
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

  networking.hostName = hostname;

  environment.systemPackages = with pkgs; [
    openvpn3
    fanctl
    nvtopPackages.full
    coolercontrol.coolercontrold
    coolercontrol.coolercontrol-liqctld
    coolercontrol.coolercontrol-gui
    coolercontrol.coolercontrol-ui-data
    mesa
    kdePackages.sddm-kcm
    gmp
    libmpc
    mpfr
    isl
    jre_minimal
  ];

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
}
