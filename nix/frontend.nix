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
    hash = "sha256-Inl7+jq7lIEl24xUBpi06Rf5xpKYKEtPROjnLYn5Q3c=";
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
