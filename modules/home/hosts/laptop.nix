{ inputs, lib, ... }:
{
  # Enforce WhiteSur window decorations on the laptop
  programs.plasma.workspace.windowDecorations = lib.mkForce {
    library = "org.kde.kwin.aurorae";
    theme = "__aurorae__svg__WhiteSur-dark";
  };

  # Also provide public SSH keys for reproducibility
  home.file.".ssh/id_ed25519_personal.pub".source = "${inputs.secrets}/keys/id_ed25519_personal.pub";
  home.file.".ssh/id_ed25519_work.pub".source = "${inputs.secrets}/keys/id_ed25519_work.pub";
}
