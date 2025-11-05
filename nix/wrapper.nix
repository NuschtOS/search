{ self, ixxPkgs, lib, nuscht-search, pkgs }:

let
  nixpkgsPkgs = pkgs;
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
                  if builtins.isAttrs value
                  then
                    if lib.isDerivation value
                    then [ newName ]
                    else
                    # We cannot handle other things like functions or plain values
                    # Do not recurse more copies of pkgs multiple times
                      if builtins.hasAttr "AAAAAASomeThingsFailToEvaluate" value
                      then builtins.trace "Skipping copy of top-level pkgs: ${builtins.concatStringsSep "." newName}" [ ]
                      else listPackages newName value
                  else
                    [ ]
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
          last = builtins.head (lib.sublist (builtins.length name - 1) 1 name);
        in
        builtins.substring 0 1 last)
      pkgNames;
in
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

  mkPackagesJSONs = { name, pkgs }:
    let
      partedList =
        let
          list = listPackages [ ] (import pkgs);
        in
        partitionPackageNames list;
    in
    lib.mapAttrsToList
      (part: attrNames:
        nixpkgsPkgs.runCommand "${name}-${part}.json"
          {
            partition = builtins.toJSON attrNames;
            passAsFile = [ "partition" ];
            nativeBuildInputs = [ nixpkgsPkgs.nixVersions.nix_2_32 ];
          }
          ''
            cp ${./build-packages.nix} build-packages.nix
            cp $partitionPath partition.nix
            cp ${pkgs} pkgs.nix
            echo ===
            cat partition.nix
            echo ===
            ls -la
            NIX_STATE_DIR=$TMPDIR NIX_PATH= nix \
              --extra-experimental-features nix-command \
              eval \
              --quiet \
              --json \
              --read-only \
              --impure \
              --show-trace \
              --expr \
              'import ./build-packages.nix { lib = import ${self.inputs.nixpkgs}; }' \
              > $out
          '')
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
