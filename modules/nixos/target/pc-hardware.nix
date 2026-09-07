{ ... }:
{
  flake.modules.nixos."target.config.pc.hardware" =
    { config, pkgs, ... }:
    {
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
      };

      # Graphics
      services.xserver.videoDrivers = [ "nvidia" ];
      programs.sway.extraOptions = [ "--unsupported-gpu" ];

      hardware.nvidia = {
        modesetting.enable = true;
        open = true;
        nvidiaSettings = true;
        # nixpkgs' `stable`/`production` channel (595.71.05-595.91.07) carries a
        # known Xid 13 "Shader Program Header" resume regression (black screen
        # after suspend). Pin nixpkgs-unstable's `new_feature` driver (610.57.04,
        # a newer major line released after the regression) instead, built
        # against our own kernelPackages to avoid a kernel/module version
        # mismatch with nixpkgs-unstable's kernel.
        # https://forums.developer.nvidia.com/t/graphical-corruption-after-suspend-resume-with-nvidia-xid-13-595-71-05/368627
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "610.57.04";
          sha256_64bit = "sha256-suk1xmuDuwDAyFe8jg7g/VLekoa0DJzB7sKafOfrEW0=";
          sha256_aarch64 = "sha256-QCefrMBCmpOwuOyXv1k5Gj0iB2CYlPgnG3JToUw/j54=";
          openSha256 = "sha256-rQHOOOY4KL92Ww3KDwh+j4eGU7oNAH8LutZC5wmFnPo=";
          settingsSha256 = "sha256-ZEMo8I8Zc2Tq6RVDNYpAH+f094dUaZiBqO+5f6lIjRI=";
          persistencedSha256 = "sha256-aXmD2VY1RLlgAnlHhOUMWzvMyhI6JTClcFLm4imF/mA=";
        };
      };

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          mesa
          libva-utils
        ];
      };
    };
}
