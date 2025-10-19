# Main Home Manager configuration modules
{
  hostname ? null,
  ...
}:
let
  # Optional host-specific configuration
  hostConfig =
    if hostname != null && builtins.pathExists ./hosts/${hostname}.nix then
      [ ./hosts/${hostname}.nix ]
    else
      [ ];
in
{
  imports = [
    ./core.nix
    ./theme/gruvbox-dark-hard.nix
    ./desktop/plasma.nix
    ./desktop/sway.nix
    ./programs
    ./packages
  ]
  ++ hostConfig;
}
