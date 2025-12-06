{ callPackage, callPackages, ixxPkgs, path, lib, stdenv, nodejs }:

{ config, data }:

let
  manifest = lib.importJSON ../package.json;
  # pin pnpm version to avoid hash mismatches with differing pnpm versions
  # on nixos stable and unstable
  pnpm' = callPackage (path + "/pkgs/development/tools/pnpm/generic.nix") {
    version = "10.24.0";
    hash = "sha256-GW9L0XTry9mXhrM0UvFEyy3DLvTnE47URJHp1D1wLXU=";
  };
  pnpm = pnpm' // {
    passthru = pnpm'.passthru // {
      inherit (callPackages (path + "/pkgs/development/tools/pnpm/fetch-deps") {
        pnpm = pnpm';
      }) fetchDeps configHook;
    };
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

  pnpmDeps = pnpm.fetchDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 2;
    postPatch = cpFixx;
    hash = "sha256-Wnh8Nh2aulN5FwFb1yfmENWTkgjjqGTKppfb6PFcLEw=";
  };

  nativeBuildInputs = [ nodejs pnpm.configHook ];

  __darwinAllowLocalNetworking = true;

  buildPhase = ''
    pnpm run build:ci --base-href ${config.baseHref} | cat
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
