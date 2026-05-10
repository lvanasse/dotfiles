{ ... }:
{
  flake.modules.nixos."target.config.pc.networking" =
    { pkgs, ... }:
    {
      # PC-specific networking
      networking = {
        useNetworkd = true;
        interfaces.enp5s0.useDHCP = true;
        networkmanager.dns = "systemd-resolved";
        # Cisco AnyConnect-compatible VPN support via OpenConnect.
        networkmanager.plugins = [ pkgs.networkmanager-openconnect ];
      };

      # Persist Wake-on-LAN across boots and carrier resets on the real NIC.
      systemd.network.links."10-enp5s0-wol" = {
        matchConfig.OriginalName = "enp5s0";
        linkConfig.WakeOnLan = "magic";
      };
    };
}
