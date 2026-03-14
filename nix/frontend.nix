{
 callPackage,
 emptyDirectory,
 fetchPnpmDeps,
 lib,
 nodejs,
 path,
 pnpmConfigHook,
 stdenv,

 baseHref ? "/",
 title ? "NuschtOS Search",
 data ? emptyDirectory,
}:

let
  manifest = lib.importJSON ../package.json;
  # pin pnpm version to avoid hash mismatches with differing pnpm versions
  # on nixos stable and unstable
  pnpm = callPackage (path + "/pkgs/development/tools/pnpm/generic.nix") {
    version = "10.26.1";
    hash = "sha256-6ObkmRKPaAT1ySIjzR8uP2JVcQLAxuJUzJm7KqIpu/k=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = manifest.name;
  inherit (manifest) version;

  src = lib.cleanSourceWith {
    filter = name: _: ((!lib.hasSuffix ".nix" name) && (builtins.dirOf name) != "node_modules");
    src = lib.cleanSource ./..;
  };

  postPatch = ''
    substituteInPlace src/app/core/config.domain.ts src/index.html \
      --replace-fail '##TITLE##' ${lib.escapeShellArg title}
    ln -s ${data}/{meta,index.ixx} public
  '';

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 3;
    hash = "sha256-YdhFjQE8YyOF8YBX/Z8uulB3kkmpY+z9OYrqtAv+U3I=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    (pnpmConfigHook.override { inherit pnpm; })
  ];

  __darwinAllowLocalNetworking = true;

  buildPhase = ''
    pnpm run build:ci --base-href ${baseHref}
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -rL ./dist/browser/* $out/
    cp ./dist/3rdpartylicenses.txt $out
    runHook postInstall
  '';

  passthru = {
    inherit pnpm;
  };
})
