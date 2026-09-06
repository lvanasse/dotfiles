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
        package = config.boot.kernelPackages.nvidiaPackages.stable;
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
