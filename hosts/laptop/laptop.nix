{
  inputs,
  hostname,
  username,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common/system.nix
    ../../modules/common/users.nix
  ];

  networking.hostName = hostname;

}
