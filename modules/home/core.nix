{ config, ... }:
let
  username = config.flake.lib.username;
in
{
  flake.modules.homeManager.core =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      # Core Home Manager configuration
      nixpkgs.config = {
        allowUnfree = true;
      };

      # Ensure ad-hoc nix commands (nix shell/build/run) allow unfree packages
      xdg.configFile."nixpkgs/config.nix".text = ''
        { allowUnfree = true; }
      '';

      home = {
        enableNixpkgsReleaseCheck = false;
        username = lib.mkDefault username;
        homeDirectory = lib.mkDefault "/home/${username}";
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
