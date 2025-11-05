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

  mkPackagesJSONs =
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
        // lib.optionalAttrs (derv ? version) { version = toString derv.version; }
        // lib.optionalAttrs (derv ? outputs) { inherit (derv) outputs; }
        // lib.optionalAttrs (derv ? meta)
          (
            lib.optionalAttrs (derv.meta ? description) { inherit (derv.meta) description; }
            // lib.optionalAttrs
              (derv.meta ? homepage
              # TODO: remove when https://github.com/NixOS/nixpkgs/pull/458597 is merged
              && derv.meta.homepage != "")
              { inherit (derv.meta) homepage; }
            // lib.optionalAttrs (derv.meta ? broken) { inherit (derv.meta) broken; }
            // lib.optionalAttrs (derv.meta ? license) { licenses = [ (extractLicense derv.meta.license) ]; }
            // lib.optionalAttrs (derv.meta ? licenses) { licenses = map extractLicense derv.meta.licenses; }
            // lib.optionalAttrs (derv.meta ? insecure) { inherit (derv.meta) insecure; }
            // lib.optionalAttrs (derv.meta ? maintainerIDs) {
              # NOTE: meta.teams is already contained in meta.maintainers
              maintainers = map (m: m.githubId) (derv.meta.maintainers.members or derv.meta.maintainers);
            }
            // lib.optionalAttrs (derv.meta ? unfree) { inherit (derv.meta) unfree; }
          );

      createEvalError = newName: {
        attrName = builtins.concatStringsSep "." newName;
        evalError = true;
      };

      listPackages = attrPrefix: pkgs:
        lib.foldlAttrs
          (acc: name: value:
            #builtins.trace "${if attrPrefix == null then "" else builtins.concatStringsSep "." attrPrefix}.${name}"
            (
              if attrPrefix != [ ] && builtins.elemAt attrPrefix (builtins.length attrPrefix - 1) == name
                # TODO: go through this and sort and comment
                || name == "scope"
                # TODO: list tests
                || name == "tests" || name == "nixosTests" || name == "vm-variant"
                # we are not noogle, yet
                || name == "lib"
                # formatter types
                || name == "functor"
                # avoid infinite recursions when traversing package sets
                || name == "pkgs"
                # override infrastructure
                || name == "override" || name == "__functionArgs" || name == "__functor" || name == "overrideDerivation"
                # cross-compilation infrastructure
                || name == "__splicedPackages" || name == "buildPackages"
                # alias to pkgs in stable; throw in unusable
                || name == "gitAndTools"
                # uses to much ram
                || name == "haskell"
                || name == "haskellPackages"
                # don't recurse into pythonPackages a nth time and just assume and attrPrefix ending in Packages (eg. python311Packages or mopidyPackages) is not what we want
                || (attrPrefix != [ ] && lib.hasSuffix "Packages" (lib.head attrPrefix) && name == "pythonPackages")
              then acc
              else
                acc ++ (
                  let
                    newName = attrPrefix ++ [ name ];
                    # in if lib.isDerivation value then
                    evalResult = builtins.tryEval (
                      if lib.isDerivation value
                      then [ newName ]
                      else
                      # We cannot handle other things like functions or plain values
                        if builtins.isAttrs value
                        then
                        # Do not recurse more copies of pkgs multiple times
                          if builtins.hasAttr "AAAAAASomeThingsFailToEvaluate" value
                          then builtins.trace "Skipping copy of top-level pkgs: ${builtins.concatStringsSep "." newName}" [ ]
                          else listPackages newName value
                        else
                          builtins.trace "Pkg is not an attr?!: ${builtins.concatStringsSep "." newName}" [ ]
                    );
                  in
                  if !evalResult.success then
                    builtins.trace "Failed to evaluate pkg: ${builtins.concatStringsSep "." newName}"
                      # TODO: add eval Error to package list
                      [ ]
                  else
                    evalResult.value
                )
            ))
          [ ]
          pkgs;

      partitionPackageNames = pkgNames:
        builtins.groupBy
          # TODO: partition python3XX
          (name:
            let
              last = lib.sublist (builtins.length name - 1) 1 name;
            in
            builtins.substring 0 2 last)
          pkgNames;

    in
    { name, pkgs }:
    let
      list = listPackages [ ] pkgs;

      partedList = partitionPackageNames list;
    in
    lib.mapAttrsToList
      (part: attrNames:
        pkgs.writers.writeJSON "${name}-${part}" (map
          (attrName:
            let
              derv = lib.getAttrFromPath attrName pkgs;
              pkg = mkPackage attrName derv;
              # tryEval (deepSeq ...) makes sure we catch all potential throws in all attributes early on
              # NOTE: running deepSeq on any derivation results in an infinite recursion due to stdenv.passthru generating a warning
              pkgEvalResult = builtins.tryEval (builtins.deepSeq pkg pkg);
            in
            if pkgEvalResult.success then
              pkgEvalResult.value
            else
            # TODO: !!!
            # createEvalError attrName;
              "asdasdasd"
          )
          attrNames)
      )
      partedList;

  mkSearchData = pkgs.callPackage ({ scopes, runCommand }:
    let
      config.scopes = map
        (scope: {
          inherit (scope) urlPrefix;
        } // lib.optionalAttrs (scope?name) { inherit (scope) name; }
        // lib.optionalAttrs (scope?optionsPrefix) { inherit (scope) optionsPrefix; }
        // lib.optionalAttrs (scope?optionsJSON || scope?modules) {
          optionsJson = scope.optionsJSON or (mkOptionsJSON {
            modules = scope.modules or (throw "A scope requires either optionsJSON or module!");
            specialArgs = scope.specialArgs or { };
            overrideEvalModulesArgs = scope.overrideEvalModulesArgs or { };
          });
        } // lib.optionalAttrs (scope?pkgs) {
          packagesJsons = mkPackagesJSONs {
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
