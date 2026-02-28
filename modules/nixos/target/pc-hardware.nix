{ ... }:
{
  flake.modules.nixos."targetConfig.pc.hardware" =
    { pkgs, ... }:
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
    };
}
