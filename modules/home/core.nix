{
  config,
  inputs,
  lib,
  ...
}:
let
  username = config.flake.lib.username;
  atticCachePublicKeyFile = "${inputs.secrets}/server/attic-cache-public-key";
  hasAtticCachePublicKey = builtins.pathExists atticCachePublicKeyFile;
  atticCachePublicKey = lib.strings.removeSuffix "\n" (builtins.readFile atticCachePublicKeyFile);
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
        permittedInsecurePackages = [
          # Required by bitwarden-desktop 2026.5.0 on NixOS 26.05.
          "electron-39.8.10"
        ];
      };

      # Ensure ad-hoc nix commands (nix shell/build/run) allow unfree packages
      xdg.configFile."nixpkgs/config.nix".text = ''
        {
          allowUnfree = true;
          permittedInsecurePackages = [
            "electron-39.8.10"
          ];
        }
      '';

      xdg.configFile."nix/nix.conf".text = ''
        experimental-features = nix-command flakes
        substituters = https://cache.nixos.org/ https://cache.numtide.com${lib.optionalString hasAtticCachePublicKey " http://server.tail7e8d6c.ts.net:8080/dotfiles"}
        trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=${lib.optionalString hasAtticCachePublicKey " ${atticCachePublicKey}"}
      '';

      home = {
        enableNixpkgsReleaseCheck = false;
        username = lib.mkDefault username;
        homeDirectory = lib.mkDefault "/home/${username}";
        stateVersion = "25.11";
        packages = [
          pkgs.attic-client
          pkgs.ripgrep
        ];

        sessionVariables = {
          NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
          # Ensure TLS inside Emacs and other tools works for HTTPS package archives
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          SSL_CERT_DIR = "${pkgs.cacert}/etc/ssl/certs";
          # Provide a reliable <nixpkgs> path for tools like nixd.
          NIX_PATH = "nixpkgs=${pkgs.path}";
        };
      };
    };
}
