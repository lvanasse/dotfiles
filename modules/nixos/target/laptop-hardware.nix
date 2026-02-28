{ ... }:
{
  flake.modules.nixos."targetConfig.laptop.hardware" =
    { pkgs, ... }:
    {
      # Boot configuration
      boot.loader.grub = {
        enable = true;
        device = "nodev";
        useOSProber = true;
        efiSupport = true;
      };
      boot.loader.efi.canTouchEfiVariables = true;

      # Laptop-specific features
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;

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
