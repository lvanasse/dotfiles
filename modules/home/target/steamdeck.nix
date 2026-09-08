{ ... }:
{
  flake.modules.homeManager."target.config.steamdeck" =
    { pkgs, ... }:
    let
      # The nixpkgs package uses buildFHSEnv, which adds an outer Linux
      # container around UMU's own pressure-vessel runtime. On SteamOS that
      # hides the host Mesa driver and makes games fail to load radeonsi.
      # Use UMU's official user-install zipapp directly instead.
      umuLauncherNative = pkgs.stdenvNoCC.mkDerivation {
        pname = "umu-launcher-native";
        version = "1.4.4";

        src = pkgs.fetchurl {
          url = "https://github.com/Open-Wine-Components/umu-launcher/releases/download/1.4.4/umu-launcher-1.4.4-zipapp.tar";
          hash = "sha256-61kGkYQff60/w62P1dtMy4eEn+eUjmKyjs56TuSMyFE=";
        };

        dontUnpack = true;
        nativeBuildInputs = [ pkgs.makeWrapper ];

        installPhase = ''
          runHook preInstall
          mkdir -p "$out/bin" "$out/libexec"
          tar -xf "$src" --strip-components=1 -C "$out/libexec"
          makeWrapper ${pkgs.python3}/bin/python3 "$out/bin/umu-run" \
            --add-flags "$out/libexec/umu-run"
          runHook postInstall
        '';
      };
    in
    {
      home.username = "deck";
      home.homeDirectory = "/home/deck";

      home.packages = with pkgs; [
        home-manager
        steamtinkerlaunch
        umuLauncherNative
        xrdp
        pulseaudio-module-xrdp
      ];
    };
}
