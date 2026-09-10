{ ... }:
{
  flake.modules.homeManager."target.config.work-laptop" =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      homeDir = config.home.homeDirectory;
      bootstrapIdentity = "${homeDir}/.ssh/id_ed25519_work_laptop_bootstrap";
      personalKeyAge = "${inputs.secrets}/ssh/id_ed25519_personal.age";
      workKeyAge = "${inputs.secrets}/ssh/id_ed25519_work.age";
      hasPersonalKeyAge = builtins.pathExists personalKeyAge;
      hasWorkKeyAge = builtins.pathExists workKeyAge;
    in
    {
      services.ntfySubscriber = {
        enable = true;
        device = "work-laptop";
      };

      age.identityPaths = lib.mkForce [
        bootstrapIdentity
        "${homeDir}/.ssh/id_ed25519_personal"
        "${homeDir}/.ssh/id_ed25519_work"
      ];
      programs.git.settings.user = {
        name = "Ludovic Vanasse";
        email = "ludovic.vanasse@vention.cc";
      };
      programs.ssh.settings."github.com".identityFile = lib.mkForce "~/.ssh/id_ed25519_work";
      age.secrets =
        lib.optionalAttrs hasPersonalKeyAge {
          "ssh-id-ed25519-personal" = {
            file = personalKeyAge;
            path = "${homeDir}/.ssh/id_ed25519_personal";
            mode = "0600";
          };
        }
        // lib.optionalAttrs hasWorkKeyAge {
          "ssh-id-ed25519-work" = {
            file = workKeyAge;
            path = "${homeDir}/.ssh/id_ed25519_work";
            mode = "0600";
          };
        };

      # Keep the existing local public key file to avoid clobbering the bootstrap key path.
      home.file.".ssh/id_ed25519_personal.pub".enable = lib.mkForce false;

      # VS Code white-screen workaround (work-laptop only).
      # On Sway/Wayland with multiple displays, Electron's offscreen compositor
      # sometimes fails to paint webviews, leaving a blank pane that reads
      # "No content for off screen to display" until the window is moved/resized.
      # Disabling GPU hardware acceleration routes rendering through the CPU and
      # eliminates the glitch.
      home.file.".config/Code/argv.json".text = builtins.toJSON {
        "disable-hardware-acceleration" = true;
      };
    };
}
