{ inputs, ... }:
let
  unstablePackages = _final: prev: {
    unstable = import inputs."nixpkgs-unstable" {
      system = prev.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };

  # Use a coherent unstable KDE/Qt package set while keeping the rest of the
  # system on the stable nixpkgs input.
  latestPlasma = _final: prev: {
    kdePackages = prev.unstable.kdePackages;
    qt6 = prev.unstable.qt6;
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

  sonarlintHashFix = _final: prev: {
    sonarlint-ls = prev.callPackage ../../overrides/sonarlint-ls/package.nix { };
  };

  # Ensure agenix is always available via pkgs, even if nixpkgs drops it.
  agenixFromInput =
    _final: prev:
    if prev ? agenix then
      { }
    else
      {
        agenix = inputs.agenix.packages.${prev.stdenv.hostPlatform.system}.default;
      };

in
{
  flake.overlays = {
    inherit
      unstablePackages
      latestPlasma
      qbittorrent510_2505
      agenixFromInput
      sonarlintHashFix
      ;
  };
}
