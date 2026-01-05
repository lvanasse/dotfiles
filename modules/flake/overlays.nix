{ inputs, ... }:
let
  # Pull codex from nixpkgs-unstable so it tracks its latest available build
  codexFromUnstable =
    _final: prev:
    let
      system = prev.stdenv.hostPlatform.system;
      unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
    in
    {
      codex = unstable.codex;
    };

  qbittorrent510_2505 =
    _final: prev:
    let
      pkgs2505 = import inputs."nixpkgs-2505" {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    in
    {
      qbittorrent = pkgs2505.qbittorrent;
    };

  # Fix broken upstream hash for sonarlint-ls fetched Maven deps
  sonarlintHashFix = _final: prev: {
    sonarlint-ls = prev.callPackage ../../overrides/sonarlint-ls/package.nix { };
  };

in
{
  flake.overlays = {
    inherit
      codexFromUnstable
      qbittorrent510_2505
      sonarlintHashFix
      ;
  };
}
