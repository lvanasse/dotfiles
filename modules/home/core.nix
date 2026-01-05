{ config, ... }:
let
  username = config.flake.lib.username;
in
{
  flake.modules.homeManager.core =
    { config, pkgs, ... }:
    {
      # Core Home Manager configuration
      nixpkgs.config = {
        allowUnfree = true;
      };

      home = {
        enableNixpkgsReleaseCheck = false;
        inherit username;
        homeDirectory = "/home/${username}";
        stateVersion = "25.11";

        sessionVariables = {
          NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
          # Ensure TLS inside Emacs and other tools works for HTTPS package archives
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          SSL_CERT_DIR = "${pkgs.cacert}/etc/ssl/certs";
        };
      };
    };
}
