{ inputs, ... }:
let
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

  # Keep jira-cli-go pinned from unstable, but expose it through pkgs.
  jiraCliFromUnstable =
    _final: prev:
    let
      pkgsUnstable = import inputs."nixpkgs-unstable" {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    in
    if pkgsUnstable ? jira-cli-go then
      {
        jira-cli-go = pkgsUnstable.jira-cli-go;
      }
    else
      { };

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
      qbittorrent510_2505
      jiraCliFromUnstable
      agenixFromInput
      sonarlintHashFix
      ;
  };
}
