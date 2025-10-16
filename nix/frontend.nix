{ callPackage, callPackages, path, lib, stdenv, nodejs, emptyDirectory, baseHref ? "/", title ? "NuschtOS Search", data ? emptyDirectory }:

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
    substituteInPlace src/app/core/config.domain.ts src/index.html \
      --replace-fail '##TITLE##' ${lib.escapeShellArg title}
    ln -s ${data}/{meta,index.ixx} public
  '';

  pnpmDeps = pnpm.fetchDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 2;
    hash = "sha256-9RWQCPSBIcMLqLRHmfoGC7nQU5ZcGfwdSgw8gfZTJ10=";
  };

  nativeBuildInputs = [ nodejs pnpm.configHook ];

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
