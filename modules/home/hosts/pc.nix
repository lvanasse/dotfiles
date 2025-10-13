{ inputs, ... }:
{
  # Ensure public SSH keys are present for reproducibility
  home.file.".ssh/id_ed25519_personal.pub".source = "${inputs.secrets}/keys/id_ed25519_personal.pub";
  home.file.".ssh/id_ed25519_work.pub".source = "${inputs.secrets}/keys/id_ed25519_work.pub";

  # Hyprland (Home Manager, PC-only). Scoped to hyprland-session via systemd integration
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true; # ensures Hyprland user services don't run under KDE
    # Minimal config to silence HM warning; real config can be added later.
    settings = { };
    extraConfig = "# managed by Home Manager";
  };
}
