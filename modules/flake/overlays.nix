{ inputs, ... }:
let
  unstablePackages =
    _final: prev:
    {
      unstable = import inputs."nixpkgs-unstable" {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
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

  # Ensure agenix is always available via pkgs, even if nixpkgs drops it.
  agenixFromInput =
    _final: prev:
    if prev ? agenix then
      { }
    else
      {
        agenix = inputs.agenix.packages.${prev.stdenv.hostPlatform.system}.default;
      };

  # Tune llm-agents' Codex build for local compile speed.
  codexBuildTuning =
    _final: prev:
    let
      tunedCodex = prev.llm-agents.codex.overrideAttrs (old: {
        preBuild =
          (old.preBuild or "")
          + ''
            if grep -q 'codegen-units = 1' Cargo.toml; then
              substituteInPlace Cargo.toml \
                --replace-fail 'codegen-units = 1' 'codegen-units = 16'
            fi
          '';
      });
    in
    {
      codex = tunedCodex;
      llm-agents = prev.llm-agents // {
        codex = tunedCodex;
      };
    };

in
{
  flake.overlays = {
    inherit
      unstablePackages
      qbittorrent510_2505
      agenixFromInput
      codexBuildTuning
      sonarlintHashFix
      ;
  };
}
