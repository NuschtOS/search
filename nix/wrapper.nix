{ self, ixxPkgs, lib, nix-index-database, nuscht-search, pkgs }:

let
  nixpkgsPkgs = pkgs;

  shouldRemoved = attrPrefix: name: value:
    attrPrefix != [ ]
    && builtins.elemAt attrPrefix (builtins.length attrPrefix - 1) == name
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
    || !(builtins.isAttrs value);

  listPackages = attrPrefix: pkgs:
    let
      pkgsAndPkgSets = lib.filterAttrs (name: value: !(builtins.tryEval (shouldRemoved attrPrefix name value)).value) pkgs;
      rawPkgNames = builtins.attrNames (lib.filterAttrs (_name: value: !(builtins.tryEval (!(lib.isDerivation value))).value) pkgsAndPkgSets);
    in
    (
      let
        finalPkgs = map (name: attrPrefix ++ [ name ]) rawPkgNames;
      in
      finalPkgs
    ) ++ (
      let
        finalPkgs =
          let
            pkgSets = lib.filterAttrs (name: value: !(builtins.elem name rawPkgNames) && !(builtins.tryEval (builtins.hasAttr "AAAAAASomeThingsFailToEvaluate" value)).value) pkgsAndPkgSets;
          in
          lib.mapAttrs (name: value: listPackages (attrPrefix ++ [ name ]) value) pkgSets;
      in
      builtins.concatMap (x: x) (builtins.attrValues finalPkgs)
    );

  partitionPackageNames = pkgNames:
    builtins.groupBy
      (name:
        let
          last = builtins.head (lib.sublist (builtins.length name - 1) 1 name);
        in
        lib.toLower (builtins.substring 0 1 last)
      )
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
            cp $partitionPath partition.json
            cp ${pkgs} pkgs.nix
            NIX_STATE_DIR=$TMPDIR NIX_PATH= nix \
              --extra-experimental-features nix-command \
              eval \
              --impure \
              --json \
              --offline \
              --quiet \
              --read-only \
              --show-trace \
              --expr \
              'import ./build-packages.nix { inherit (import ${self.inputs.nixpkgs} {}) lib; }' \
              > $out
          '')
      partedList;

  mkCollectManDerivations = let
    list = pkgs.runCommand "list-man-derivations" {
      nativeBuildInputs = [ pkgs.nix-index ];
    } ''
      mkdir tmp
      ln -s ${nix-index-database} tmp/files
      NIX_INDEX_DATABASE=tmp nix-locate share/man/man | awk '{print $1}' | grep .man | sort -u > $out
    '';
  in
    pkgs.runCommand "man-derivations" { }
      (lib.concatMapStringsSep "\n" (p: ''
        mkdir -p $out/${p.name}
        cp -rv --no-preserve=all ${p}/share/man/man* $out/${p.name}/
      '')
      (lib.filter (p: p != null)
        (map
          (p: lib.attrByPath (lib.splitString "." p) (lib.trace "Could not find package ${p}" null) pkgs)
          (lib.filter (p: p != "") (lib.splitString "\n" (lib.readFile list)))
        ))
      );

  mkSearchData = pkgs.callPackage ({ scopes, runCommand }:
    let
      config.scopes = map
        (scope: {
          inherit (scope) urlPrefix;

          licenseMapping = builtins.toJSON (lib.mapAttrs (_n: v:
            lib.removeAttrs v [ "deprecated" "shortName" ]
          ) (scope.licenses or lib.licenses));

          maintainerMapping = builtins.toJSON (lib.mapAttrs' (_n: v:
            lib.nameValuePair (toString v.githubId) (lib.removeAttrs v [ "githubId" "keys" ])
          ) (scope.maintainers or lib.maintainers));
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
