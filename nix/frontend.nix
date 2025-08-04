{ callPackage, callPackages, path, lib, stdenv, nodejs, emptyDirectory, baseHref ? "/", title ? "NuschtOS Search", data ? emptyDirectory }:

let
  manifest = lib.importJSON ../package.json;
  # pin pnpm version to avoid hash mismatches with differing pnpm versions
  # on nixos stable and unstable
  pnpm' = callPackage (path + "/pkgs/development/tools/pnpm/generic.nix") {
    version = "10.13.1";
    hash = "sha256-D57UjYCJlq4AeDX7XEZBz5owDe8u3cnpV9m75HaMXyg=";
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
    substituteInPlace src/app/core/config.domain.ts src/index.html \
      --replace-fail '##TITLE##' ${lib.escapeShellArg title}
    ln -s ${data}/{meta,index.ixx} public
  '';

  pnpmDeps = pnpm.fetchDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = "2";
    hash = "sha256-izqL9QN9p5LS4WXNoXBexqCidn/qT+Kog4yUIqSlZxM=";
  };

  nativeBuildInputs = [ nodejs pnpm.configHook ];

  passthru = {
    inherit pnpm;
  };

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
})
