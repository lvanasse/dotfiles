{ ... }:
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
}
