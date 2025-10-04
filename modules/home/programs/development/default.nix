# Development programs
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./vscode.nix
    ./tools.nix
    ./git.nix
  ];
}