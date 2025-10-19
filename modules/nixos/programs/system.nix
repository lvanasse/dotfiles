# System programs and packages
{ pkgs, ... }:
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
    pavucontrol
    openssh
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
