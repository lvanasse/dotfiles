# Main Home Manager configuration modules
{
  inputs,
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
    ./programs
    ./packages
  ]
  ++ hostConfig;
}
