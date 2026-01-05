{ ... }:
{
  flake.modules.homeManager.packagesSerial =
    { pkgs, ... }:
    {
      # Serial / device utilities
      home.packages = with pkgs; [
        moserial
        putty
      ];
    };
}
