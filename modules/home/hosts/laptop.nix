{ lib, ... }:
{
  # Enforce WhiteSur window decorations on the laptop
  programs.plasma.workspace.windowDecorations = lib.mkForce {
    library = "org.kde.kwin.aurorae";
    theme = "__aurorae__svg__WhiteSur-dark";
  };

  # No secrets dependency here to keep HM standalone builds reliable
}
