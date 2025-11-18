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
    ./desktop/gtk.nix
    ./desktop/sway.nix
    ./desktop/xdg.nix
    ./programs
    ./services
    ./packages
  ]
  ++ hostConfig;
}
