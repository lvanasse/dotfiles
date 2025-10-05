# Home Manager programs
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./terminal
    ./development
  ];
}
