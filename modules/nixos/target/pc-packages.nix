{ ... }:
{
  flake.modules.nixos."target.config.pc.packages" =
    { pkgs, ... }:
    {
      # PC-specific packages
      environment.systemPackages = with pkgs; [
        fanctl
        nvtopPackages.full
        coolercontrol.coolercontrold
        coolercontrol.coolercontrol-gui
        coolercontrol.coolercontrol-ui-data
        openconnect
        mesa
        gmp
        libmpc
        mpfr
        isl
      ];
    };
}
