{ inputs, lib, ... }:
{
  # Ensure public SSH keys are present for reproducibility
  home.file.".ssh/id_ed25519_personal.pub".source = "${inputs.secrets}/keys/id_ed25519_personal.pub";
  home.file.".ssh/id_ed25519_work.pub".source = "${inputs.secrets}/keys/id_ed25519_work.pub";

  # PC-specific Sway output layout (host-only)
  wayland.windowManager.sway.extraConfig = lib.mkAfter ''
    # Displays (from sway-export-outputs)
    output DVI-D-1 mode 1920x1080@60Hz
    output DVI-D-1 pos 0 1080
    output DVI-D-1 transform 90
    output HDMI-A-2 mode 1920x1080@60Hz
    output HDMI-A-2 pos 3000 1080
    output HDMI-A-1 mode 1920x1080@60Hz
    output HDMI-A-1 pos 1080 1080
    output DP-2 mode 2560x1080@60Hz
    output DP-2 pos 440 0

    # Treat HDMI-A-1 as the main display by assigning primary workspaces to it
    workspace 1 output HDMI-A-1
  '';
}
