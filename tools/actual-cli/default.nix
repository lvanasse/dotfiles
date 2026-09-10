{
  actualVersion,
  buildNpmPackage,
  lib,
  makeWrapper,
  nodejs_22,
}:
(buildNpmPackage.override { nodejs = nodejs_22; }) {
  pname = "actual-cli";
  version = actualVersion;
  src = ./.;

  npmDepsHash = "sha256-6x5wSptwCiRuN64Jna7lJ4qSN2heitxR6KCsZXtW2Jo=";
  dontNpmBuild = true;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/actual-cli" "$out/bin"
    cp -r node_modules "$out/lib/actual-cli/"
    makeWrapper ${nodejs_22}/bin/node "$out/bin/actual" \
      --add-flags "$out/lib/actual-cli/node_modules/@actual-app/cli/dist/cli.js"
    ln -s actual "$out/bin/actual-cli"
    runHook postInstall
  '';

  meta = {
    description = "Official Actual Budget command-line client";
    homepage = "https://actualbudget.org/docs/api/cli/";
    license = lib.licenses.mit;
    mainProgram = "actual";
  };
}
