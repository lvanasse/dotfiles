# System programs and packages
{ pkgs, inputs, ... }:
let
  # Prefer agenix from flake input; fall back if available in nixpkgs
  agenixPkg = if pkgs ? agenix then pkgs.agenix else inputs.agenix.packages.${pkgs.system}.default;
in
{
  # System packages
  environment.systemPackages = with pkgs; [
    vim
    binutils
    elfutils
    expat
    genromfs
    picocom
    ubootTools
    utillinux
    ripgrep
    pavucontrol
    openssh
    agenixPkg
    nh
  ];

  # System programs
  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  # Disable legacy command-not-found (uses channels DB and is noisy)
  programs.command-not-found.enable = false;

  programs.java = {
    enable = true;
    package = pkgs.openjdk21;
  };
}
