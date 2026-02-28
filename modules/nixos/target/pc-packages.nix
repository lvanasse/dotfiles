{ ... }:
{
  flake.modules.nixos."targetConfig.pc.packages" =
    { pkgs, ... }:
    {
      # PC-specific packages
      environment.systemPackages = with pkgs; [
        fanctl
        nvtopPackages.full
        coolercontrol.coolercontrold
        coolercontrol.coolercontrol-gui
        coolercontrol.coolercontrol-ui-data
        mesa
        gmp
        libmpc
        mpfr
        isl
      ];
    };
}
