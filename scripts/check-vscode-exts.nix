let
  flake = builtins.getFlake (toString ./..);
  pkgs = import flake.inputs.nixpkgs {
    system = "x86_64-linux";
    overlays = [ flake.inputs.nix-vscode-extensions.overlays.default ];
    config.allowUnfree = true;
  };
  publishers = [
    "openai"
    "mcu-debug"
    "jebbs"
    "mkhl"
    "jeff-hykin"
    "rust-lang"
    "ms-vscode"
    "jdinhlife"
    "jnoortheen"
    "bbenoist"
    "vscode-icons-team"
    "streetsidesoftware"
    "redhat"
    "foxundermoon"
    "github"
    "marus25"
    "james-yu"
  ];
in
builtins.listToAttrs (
  map (p: {
    name = p;
    value = builtins.hasAttr p pkgs.vscode-marketplace;
  }) publishers
)
