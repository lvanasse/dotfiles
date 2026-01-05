{ config, ... }:
{
  flake.modules.homeManager.packages =
    { ... }:
    {
      imports = [
        config.flake.modules.homeManager.packagesDevelopment
        config.flake.modules.homeManager.packagesDesktop
        config.flake.modules.homeManager.packagesCad
        config.flake.modules.homeManager.packagesCompat
        config.flake.modules.homeManager.packagesContainers
        config.flake.modules.homeManager.packagesSerial
        config.flake.modules.homeManager.packagesGaming
      ];
    };
}
