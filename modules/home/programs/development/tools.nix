# Development tools and environment
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs.emacs = {
    enable = true;
    package = pkgs.emacs;
    extraPackages = epkgs: [
      epkgs.gruvbox-theme
    ];
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "${config.home.homeDirectory}/Code/personal/dotfiles";
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.java = {
    enable = true;
    package = pkgs.openjdk21;  # Full JDK instead of minimal JRE
  };
}