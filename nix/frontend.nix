{ lib, stdenv, pnpm, nodejs, baseHref ? "/", title ? "NuschtOS Search" }:

let
  manifest = lib.importJSON ../package.json;
in
stdenv.mkDerivation (finalAttrs: {
  pname = manifest.name;
  inherit (manifest) version;

  src = lib.cleanSourceWith {
    filter = name: type: ((!lib.hasSuffix ".nix" name) && (builtins.baseNameOf name) != "options.json" && (builtins.dirOf name) != "node_modules");
    src = lib.cleanSource ./..;
  };

  postPatch = ''
    substituteInPlace src/app/core/config.domain.ts \
      --replace-fail '##TITLE##' '${title}'
    substituteInPlace src/index.html \
      --replace-fail '##TITLE##' '${title}'
  '';

  pnpmDeps = pnpm.fetchDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-LrVTrAxlG+U5nr4TLpkHzK6cgKdd3d3px2Cil9Lby8U=";
  };

  nativeBuildInputs = [ nodejs pnpm.configHook ];

  buildPhase = ''
    pnpm run build:ci --base-href ${baseHref}
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r ./dist/browser/* $out/
    runHook postInstall
  '';
})
