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

  programs.java = {
    enable = true;
    package = pkgs.openjdk21;
  };
}
