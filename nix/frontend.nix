{ callPackage, ixxPkgs, path, lib, stdenv, nodejs, fetchPnpmDeps, pnpmConfigHook}:

{ config, data }:

let
  manifest = lib.importJSON ../package.json;
  # pin pnpm version to avoid hash mismatches with differing pnpm versions
  # on nixos stable and unstable
  pnpm = callPackage (path + "/pkgs/development/tools/pnpm/generic.nix") {
    version = "10.26.1";
    hash = "sha256-6ObkmRKPaAT1ySIjzR8uP2JVcQLAxuJUzJm7KqIpu/k=";
  };

  cpFixx = ''
    cp ${ixxPkgs.fixx.dist}/*.tgz .
  '';
in
stdenv.mkDerivation (finalAttrs: {
  pname = manifest.name;
  inherit (manifest) version;

  src = lib.cleanSourceWith {
    filter = name: _: ((!lib.hasSuffix ".nix" name) && (builtins.dirOf name) != "node_modules");
    src = lib.cleanSource ./..;
  };

  postPatch = ''
    substituteInPlace src/index.html \
      --replace-fail '##TITLE##' ${lib.escapeShellArg config.title}

    mkdir public/data
    ln -s ${data}/* public/data

    cat << EOF >src/app/core/config.json
    ${builtins.toJSON config}
    EOF
  '' + cpFixx;

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 3;
    postPatch = cpFixx;
    hash = "sha256-ehDA9hjhk+CBwL7nGpwPYvOnZEo3EgJrDjKU2l1BW5c=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    (pnpmConfigHook.override { inherit pnpm; })
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
    runHook postInstall
  '';

  passthru = {
    inherit config data pnpm;
  };
})
