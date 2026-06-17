{ callPackage, path, lib, stdenv, nodejs_24, fetchPnpmDeps, pnpmConfigHook }:

{ config, data }:

let
  manifest = lib.importJSON ../package.json;
  # pin pnpm version to avoid hash mismatches with differing pnpm versions
  # on nixos stable and unstable
  pnpm = callPackage (path + "/pkgs/development/tools/pnpm/generic.nix") {
    version = "11.1.2";
    hash = "sha256-v+TSssejIQVlu6YpKfnv5JPrXyRicgGhAupFFOroz4A=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = manifest.name;
  inherit (manifest) version;

  src = lib.cleanSourceWith {
    filter = name: _: ((!lib.hasSuffix ".nix" name) && (baseNameOf name) != "node_modules");
    src = ./..;
  };

  __structuredAttrs = true;
  strictDeps = true;

  postPatch = ''
    substituteInPlace src/index.html \
      --replace-fail '##TITLE##' ${lib.escapeShellArg config.title}
    substituteInPlace public/opensearch-options.xml public/opensearch-packages.xml \
      --replace-fail '##TITLE##' ${lib.escapeShellArg config.title}

    # remove development files
    rm -rf public/data
    cp -r ${data} public/data

    cat << EOF >src/app/core/config.json
    ${builtins.toJSON config}
    EOF
  '';

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 4;
    #postPatch = cpFixx;
    hash = "sha256-XUreJ+eQOsb46gZZtnx42NV6JFCqUZTAOvG8R6+5/Bc=";
  };

  nativeBuildInputs = [
    nodejs_24
    pnpm
    pnpmConfigHook
  ];

  __darwinAllowLocalNetworking = true;

  buildPhase = ''
    pnpm run build:ci --base-href ${config.baseHref}
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -rL ./dist/browser/* $out/
    cp ./dist/3rdpartylicenses.txt $out
    # support for GitHub Pages
    cp $out/index.html $out/404.html
    runHook postInstall
  '';

  passthru = {
    inherit config data pnpm;
  };
})
