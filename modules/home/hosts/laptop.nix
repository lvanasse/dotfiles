{ lib, ... }:
{
  # Keep laptop in sync with Breeze decorations for performance & consistency
  programs.plasma.workspace.windowDecorations = lib.mkForce {
    library = "org.kde.kdecoration2";
    theme = "Breeze";
  };

  # No secrets dependency here to keep HM standalone builds reliable
}
