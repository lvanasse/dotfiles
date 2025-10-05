# Terminal programs
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./zsh.nix
    ./fish.nix
    ./starship.nix
  ];
}
