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
      mkPackage = attrName: derv:
        { attrName = builtins.concatStringsSep "." attrName; inherit (derv) name; }
        // lib.optionalAttrs (derv ? pname) { inherit (derv) pname; }
        # toString because of fetchpatch and fetchpatch2
        // lib.optionalAttrs (derv ? version) { version = toString derv.version; }
        // lib.optionalAttrs (derv ? outputs) { inherit (derv) outputs; }
        // lib.optionalAttrs (derv ? meta)
          (
            lib.optionalAttrs (derv.meta ? description) { inherit (derv.meta) description; }
            // lib.optionalAttrs (derv.meta ? homepage) { inherit (derv.meta) homepage; }
            // lib.optionalAttrs (derv.meta ? broken) { inherit (derv.meta) broken; }
            // lib.optionalAttrs (derv.meta ? license) { inherit (derv.meta) license; }
            // lib.optionalAttrs (derv.meta ? insecure) { inherit (derv.meta) insecure; }
            // lib.optionalAttrs (derv.meta ? maintainers) { inherit (derv.meta) maintainers; }
            // lib.optionalAttrs (derv.meta ? unfree) { inherit (derv.meta) unfree; }
          );
      mkPackageSet = attrPrefix: pkgs:
        lib.foldlAttrs
          (acc: name: value:
            builtins.trace (if attrPrefix == null then name else "${builtins.concatStringsSep "." attrPrefix}.${name}") (
              if attrPrefix != null && builtins.elemAt attrPrefix (builtins.length attrPrefix - 1) == name || name == "__splicedPackages" || name == "buildPackages" || name == "lib" || name == "pkgs" || name == "tests" || name == "scope" || name == "nixosTests" || name == "vm-variant" || name == "bintoolsNoLibc"
                # alias to pkgs in stable; throw in unusable
                || name == "gitAndTools"
                # uses to mouch ram
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
                      if evalResult.value ? name
                      then [ (mkPackage newName evalResult.value) ]
                      else
                        if evalResult.value ? AAAAAASomeThingsFailToEvaluate
                        then [ ]
                        else mkPackageSet newName evalResult.value
                  else [{ attrName = builtins.concatStringsSep "." newName; evalError = true; }]
                )
            ))
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
