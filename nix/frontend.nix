{ callPackage, callPackages, path, lib, stdenv, nodejs }:

{ config, data }:

let
  manifest = lib.importJSON ../package.json;
  # pin pnpm version to avoid hash mismatches with differing pnpm versions
  # on nixos stable and unstable
  pnpm' = callPackage (path + "/pkgs/development/tools/pnpm/generic.nix") {
    version = "10.18.0";
    hash = "sha256-OWej7+KQnfMF/sS4M6ME38oXw4C2u3dnL02sTyzdN4g=";
  };
  pnpm = pnpm' // {
    passthru = pnpm'.passthru // {
      inherit (callPackages (path + "/pkgs/development/tools/pnpm/fetch-deps") {
        pnpm = pnpm';
      }) fetchDeps configHook;
    };
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
    substituteInPlace src/index.html \
      --replace-fail '##TITLE##' ${lib.escapeShellArg config.title}

    mkdir public/data
    ln -s ${data}/* public/data

    cat << EOF >src/app/core/config.json
    ${builtins.toJSON config}
    EOF
  '';

  pnpmDeps = pnpm.fetchDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 2;
    hash = "sha256-NtmIuj9KQthBeOUBh8Y+xYK4YfE1BAKty7WL0UaNL+M=";
  };

  nativeBuildInputs = [ nodejs pnpm.configHook ];

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
