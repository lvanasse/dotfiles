{ lib, ... }:
{
  flake.modules.homeManager."target.config.server" =
    { pkgs, ... }:
    {
      # Minimal server home config
      home.packages = with pkgs; [
        htop
        git
      ];

      programs.bash.enable = true;

      programs.ssh.settings = {
        pc.identityFile = lib.mkForce "~/.ssh/id_ed25519_server_to_pc";
        pc-ts.identityFile = lib.mkForce "~/.ssh/id_ed25519_server_to_pc";
      };

      programs.git = {
        enable = true;
        settings.user = {
          name = "Ludovic Vanasse";
          email = "mail@ludovicvanasse.com";
        };
      };

      # Server-specific Home Manager overrides go here
    };
}
