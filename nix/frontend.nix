{ callPackage, lib, path, stdenv, nodejs, baseHref ? "/", title ? "NuschtOS Search" }:

let
  manifest = lib.importJSON ../package.json;
  pnpm = callPackage (path + "/pkgs/development/tools/pnpm/generic.nix") {
    version = "9.12.3";
    hash = "sha256-JCNXcsxKyCpiYnzUf4NMcmZ6LOh3mahG7E6OVV4tS4s=";
  };
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
    hash = "sha256-m6u7BNVB+pkaMNAAGGBa76fsKrprHiR+o8JEbp0j0u0=";
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
