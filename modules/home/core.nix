# Core Home Manager configuration
{
  config,
  pkgs,
  username ? "ludovic",
  ...
}:
{
  nixpkgs.config = {
    allowUnfree = true;
  };

  home = {
    enableNixpkgsReleaseCheck = false;
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.05";

    sessionVariables = {
      NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
      NH_FLAKE = "${config.home.homeDirectory}/Code/personal/dotfiles";
      # Ensure TLS inside Emacs and other tools works for HTTPS package archives
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      SSL_CERT_DIR = "${pkgs.cacert}/etc/ssl/certs";
    };
  };
}
