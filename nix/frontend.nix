{ lib, stdenv, pnpm_8, nodejs, baseHref ? "/" }:

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

  pnpmDeps = pnpm_8.fetchDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-2bmu2KU/3vkQK+8uvGYkHidAuS0l7pM3F66W8NVs3I8=";
  };

  nativeBuildInputs = [ nodejs pnpm_8.configHook ];

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
