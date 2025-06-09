{ callPackage, callPackages, path, lib, stdenv, nodejs, baseHref ? "/", title ? "NuschtOS Search" }:

let
  manifest = lib.importJSON ../package.json;
  # pin pnpm version to avoid hash mismatches with differing pnpm versions
  # on nixos stable and unstable
  pnpm' = callPackage (path + "/pkgs/development/tools/pnpm/generic.nix") {
    version = "10.11.1";
    hash = "sha256-IR6ZkBSElcn8MLflg5b37tqD2SQ+t1QH6k+GUPsWH3w=";
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
    filter = name: type: ((!lib.hasSuffix ".nix" name) && (builtins.baseNameOf name) != "options.json" && (builtins.dirOf name) != "node_modules");
    src = lib.cleanSource ./..;
  };

  postPatch = ''
    substituteInPlace src/app/core/config.domain.ts src/index.html \
      --replace-fail '##TITLE##' ${lib.escapeShellArg title}
  '';

  pnpmDeps = pnpm.fetchDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-DuwKTgdG8bFwL/YClRQYD/1CHp2hVEwGW0MC/IUrqOI=";
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
    cp -r ./dist/browser/* $out/
    runHook postInstall
  '';
})
