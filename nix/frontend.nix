{
 callPackage,
 emptyDirectory,
 fetchPnpmDeps,
 lib,
 nodejs_24,
 path,
 pnpmConfigHook,
 stdenv,

 baseHref ? "/",
 title ? "NuschtOS Search",
 data ? emptyDirectory,
}:

let
  manifest = lib.importJSON ../package.json;
  # pin pnpm version to avoid hash mismatches with differing pnpm versions
  # on nixos stable and unstable
  pnpm = callPackage (path + "/pkgs/development/tools/pnpm/generic.nix") {
    version = "10.28.0";
    hash = "sha256-mwsE5ueZRVZpF/hBG7b2X9Lz4VkEJpBOhQDhrMSzNWE=";
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

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 3;
    hash = "sha256-zhB/CRxt8p0jB2KmvOM6PSGCgZ1YCMFUr07JssAtp/8=";
  };

  nativeBuildInputs = [
    nodejs_24
    pnpm
    (pnpmConfigHook.override { inherit pnpm; })
  ];

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
