{ ... }:
{
  flake.modules.homeManager."targetConfig.gateway" =
    { pkgs, ... }:
    {
      # Minimal home profile for gateway maintenance.
      home.packages = with pkgs; [
        git
        htop
      ];

      programs.bash.enable = true;
    };
}
