{ self, ixxPkgs, lib, nix-index-database, nuscht-search, pkgs }:

let
  nixpkgsPkgs = pkgs;

  shouldRemoved = attrPrefix: name: value:
    attrPrefix != [ ]
    && builtins.elemAt attrPrefix (builtins.length attrPrefix - 1) == name
    # TODO: re-enable when https://github.com/NixOS/nixpkgs/pull/437723#issuecomment-3493948379 is resolved
    || name == "tests"
    # we are not noogle, yet
    || name == "lib"
    # accesses builtins.currentSystem unconditionally
    || name == "vm-variant"
    # formatter types
    || name == "functor"
    # avoid infinite recursions when traversing package sets
    || name == "pkgs"
    # override infrastructure
    || name == "override" || name == "__functionArgs" || name == "__functor" || name == "overrideDerivation"
    # cross-compilation infrastructure
    || name == "__splicedPackages" || name == "buildPackages"
    # haskell adds all packages to buildHaskellPackages again
    || name == "buildHaskellPackages"
    # another variant of all haskell packages
    || (attrPrefix == [ "haskell" "packages" ] && name == "native-bignum")
    # we don't need head...
    || name == "ghcHEAD"
    # ... or binary variants
    || (lib.hasPrefix "ghc" name && lib.hasSuffix "Binary" name)
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
        # this also works if `last` has only one character
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
              '(import ./build-packages.nix { inherit (import ${self.inputs.nixpkgs} {}) lib; }).buildPackages' \
              > $out
          '')
      partedList;

  mkCollectManDerivations = let
    list = pkgs.runCommand "list-man-derivations" {
      nativeBuildInputs = [ pkgs.nix-index ];
    } ''
      mkdir tmp
      ln -s ${nix-index-database} tmp/files
      NIX_INDEX_DATABASE=tmp nix-locate share/man/man | awk '{print $1}' | grep -v -e PLACEHOLDER | sort -u > $out
    '';
  in
    pkgs.runCommand "man-derivations" {
      passthru = {
        inherit list;
      };
    }
      (lib.concatMapStringsSep "\n" (p: let
        pMan = lib.getMan p;
      in /* bash */ ''
        mkdir -p $out/${p.name}

        shopt -s globstar
        dirs=(${pMan}/**/share/man*)

        if [[ -d ${lib.getMan p}/share/man ]]; then
          cp -rv --no-preserve=all --update=none ${pMan}/share/man/man* $out/${p.name}/
        elif (( ''${#dirs[@]} )); then
          for d in "''${dirs[@]}"; do
              if [[ -d "$d" ]]; then
                  cp -rv --no-preserve=all --update=none $d/man* $out/${p.name}/
                  break
              fi
          done
        else
          echo "Where is the man page?"
          exit 4
        fi
      '')
      # Wrappers often use symlinkJoin which sets allowSubstitutes = false and only contain symlinks to man pages.
      # We do not want to download them as they are big, do not allow man outputs and download the complete unwrapped variant.
      (lib.filter (p: p != null && p.allowSubstitutes)
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

          licenseMapping = lib.mapAttrs (_n: v: {
            inherit (v) free fullName redistributable;
          } // lib.optionalAttrs (v?spdxId) {
            inherit (v) spdxId;
          } // lib.optionalAttrs (v?url) {
            inherit (v) url;
          }) (scope.licenses or lib.licenses);

          maintainerMapping = lib.mapAttrs' (_n: v:
            lib.nameValuePair (toString v.githubId) { inherit (v) email github matrix name; }
          ) (scope.maintainers or lib.maintainers);

          teamMappings = lib.mapAttrs (_n: v: {
            inherit (v) scope; members = map (m: m.githubId) v.members;
          }) (scope.teams or lib.teams);
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
          --meta-output $out/meta.json \
          --chunk-size 300 \
          $configPath
      '');

  # also update README examples
  mkMultiSearch = { scopes, baseHref ? "/", title ? "NüschtOS Search" }:
    nuscht-search {
      config =
      assert lib.assertMsg (lib.hasSuffix "/" baseHref) "baseHref needs a trailing slash";
      assert lib.assertMsg (lib.hasPrefix "/" baseHref) "baseHref needs to start with a slash";
      {
        inherit baseHref title;
        dataBase = "${baseHref}data/";
        optionsEnabled = builtins.any (scope: scope ? optionsJSON || scope ? modules) scopes;
        packagesEnabled = builtins.any (scope: scope ? pkgs) scopes;
      };
      data = mkSearchData { inherit scopes; };
    };

  # also update README examples
  mkSearch = { baseHref ? "/", title ? "NüschtOS Search", ... }@args:
    mkMultiSearch {
      inherit baseHref title;
      scopes = [ (lib.removeAttrs args [ "baseHref" "title" ]) ];
    };
}
