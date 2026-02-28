{ ... }:
{
  flake.modules.nixos."targetConfig.pc.networking" =
    { ... }:
    {
      # PC-specific networking
      networking = {
        useNetworkd = true;
        interfaces.enp5s0.useDHCP = true;
        networkmanager.dns = "systemd-resolved";
      };
    };
}
