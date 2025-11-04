{ ixxPkgs, lib, nuscht-search, pkgs }:

rec {
  mkOptionsJSON = pkgs.callPackage ({ modules, specialArgs, nixosOptionsDoc, overrideEvalModulesArgs ? { } }: (nixosOptionsDoc {
    inherit ((lib.evalModules ({
      modules = modules ++ [
        ({ lib, ... }: {
          options._module.args = lib.mkOption {
            internal = true;
          };
          config._module.check = false;
        })
      ];
      inherit specialArgs;
    } // overrideEvalModulesArgs))) options;
    warningsAreErrors = false;
  }).optionsJSON + /share/doc/nixos/options.json);

  mkPackagesJSON =
    let
      extractLicense = lic:
        if lib.isList lic then
          map extractLicense lic
        else if lib.isAttrs lic then
          lic.shortName or lic.fullName
            # TODO: try to remove after https://github.com/NixOS/nixpkgs/pull/458238 and https://github.com/NixOS/nixpkgs/pull/458240 is merged
            or lic.url
        else if lib.isString lic then
          lic
        else
          throw "Don't know how to handle ${toString lic}";

      mkPackage = attrName: derv:
        {
          attrName = builtins.concatStringsSep "." attrName;
          inherit (derv) name;
        }
        // lib.optionalAttrs (derv ? pname) { inherit (derv) pname; }
        # toString because of fetchpatch and fetchpatch2
        // lib.optionalAttrs (derv ? version) { version = if builtins.isString derv.version then derv.version else toString derv.version; }
        // lib.optionalAttrs (derv ? outputs) { inherit (derv) outputs; }
        // lib.optionalAttrs (derv ? meta)
          (
            lib.optionalAttrs (derv.meta ? description) { inherit (derv.meta) description; }
            // lib.optionalAttrs (derv.meta ? homepage) { inherit (derv.meta) homepage; }
            // lib.optionalAttrs (derv.meta ? broken) { inherit (derv.meta) broken; }
            // lib.optionalAttrs (derv.meta ? license) { licenses = [ (extractLicense derv.meta.license) ]; }
            // lib.optionalAttrs (derv.meta ? licenses) { licenses = map extractLicense derv.meta.licenses; }
            // lib.optionalAttrs (derv.meta ? insecure) { inherit (derv.meta) insecure; }
            // lib.optionalAttrs (derv.meta ? maintainers) { inherit (derv.meta) maintainers; }
            // lib.optionalAttrs (derv.meta ? unfree) { inherit (derv.meta) unfree; }
          );

      mkPackageSet = attrPrefix: pkgs:
        lib.foldlAttrs
          (acc: name: value:
builtins.trace "${if attrPrefix == null then "" else builtins.concatStringsSep "." attrPrefix}.${name}" (
            if attrPrefix != null && builtins.elemAt attrPrefix (builtins.length attrPrefix - 1) == name
              # TODO: go through this and sort and comment
              || name == "scope" || name == "bintoolsNoLibc"
              # we are not noogle, yet
              || name == "lib"
              # TODO: list tests
              || name == "tests" || name == "nixosTests" || name == "vm-variant"
              # avoid infinite recursions when traversing package sets
              || name == "pkgs"
              # cross-compilation infrastructure
              || name == "__splicedPackages" || name == "buildPackages"
              # alias to pkgs in stable; throw in unusable
              || name == "gitAndTools"
              # uses to much ram
              || name == "haskell"
              || name == "haskellPackages"
              # as pythonPackahes inside
              || name == "mopidyPackages"
            then acc
            else
              let
                evalResult = builtins.tryEval value;
                newName =
                  if attrPrefix == null
                  then [ name ]
                  else attrPrefix ++ [ name ];
              in
              acc ++ (
                if evalResult.success
                then
                  if !(builtins.isAttrs evalResult.value)
                  then [ ]
                  else
                    # there is a package rPackages.name ...
                    if evalResult.value ? name && builtins.isString evalResult.value.name
                    then
                      let
                        pkg = mkPackage newName evalResult.value;
                        # NOTE: running deepSeq on any derivation results in an infinite recursion due to stdenv.passthru generating a warning
                        pkgEvalResult = builtins.tryEval (builtins.deepSeq pkg pkg);
                      in
                      [
                        (if pkgEvalResult.success then pkgEvalResult.value else {
                          attrName = builtins.concatStringsSep "." newName;
                          evalError = true;
                        })
                      ]
                    else
                      if evalResult.value ? AAAAAASomeThingsFailToEvaluate
                      then [ ]
                      else mkPackageSet newName evalResult.value
                else [{ attrName = builtins.concatStringsSep "." newName; evalError = true; }]
              )
          )
          [ ]
          pkgs;
    in
    { name, pkgs }:
    pkgs.writeText name (
      builtins.toJSON (mkPackageSet null pkgs)
    );

  mkSearchData = pkgs.callPackage ({ scopes, runCommand }:
    let
      config.scopes = map
        (scope: {
          inherit (scope) urlPrefix;
        } // lib.optionalAttrs (scope?name) { inherit (scope) name; }
        // lib.optionalAttrs (scope?optionsPrefix) { inherit (scope) optionsPrefix; }
        // {
          optionsJson = scope.optionsJSON or (mkOptionsJSON {
            modules = scope.modules or (throw "A scope requires either optionsJSON or module!");
            specialArgs = scope.specialArgs or { };
            overrideEvalModulesArgs = scope.overrideEvalModulesArgs or { };
          });
          packagesJson = mkPackagesJSON {
            name = "${scope.name}-packages.json";
            inherit (scope) pkgs;
          };
        })
        scopes;
    in
    runCommand "search-meta"
      {
        config = builtins.toJSON config;
        passAsFile = [ "config" ];
        nativeBuildInputs = [ ixxPkgs.ixx ];
      }
      ''
        mkdir -p $out/{options,packages}
        ixx index \
          --options-index-output $out/options/index.ixx \
          --options-meta-output $out/options/meta \
          --packages-index-output $out/packages/index.ixx \
          --packages-meta-output $out/packages/meta \
          --chunk-size 300 \
          $configPath
      '');

  # also update README examples
  mkMultiSearch = { scopes, baseHref ? "/", title ? "NüschtOS Search" }:
    nuscht-search.override {
      inherit baseHref title;
      data = mkSearchData { inherit scopes; };
    };

  # also update README examples
  mkSearch = { baseHref ? "/", title ? "NüschtOS Search", ... }@args:
    mkMultiSearch {
      inherit baseHref title;
      scopes = [ (lib.removeAttrs args [ "baseHref" "title" ]) ];
    };
}
