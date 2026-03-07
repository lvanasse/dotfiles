{ ... }:
{
  flake.modules.homeManager."packages.serial" =
    { pkgs, ... }:
    {
      # Serial / device utilities
      home.packages = with pkgs; [
        moserial
        putty
      ];
    };
}
