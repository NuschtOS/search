{ self, ixxPkgs, lib, nix-index-database, nuscht-search, pkgs }:

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

  inherit (import ./build-packages.nix { inherit lib; }) buildPackages;

  inherit (import ./list-packages.nix { inherit lib; }) listPackages;

  inherit (import ./packages-jsons.nix { inherit lib listPackages pkgs self; }) mkPackagesJSONs;

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

  mkSearchData = pkgs.callPackage ({ scopes, chunkSize, runCommand }:
    let
      config.scopes = map
        (scope: {
          inherit (scope) urlPrefix;

          licenseMapping = lib.mapAttrs (_n: v: {
            redistributable = v.redistributable or false;
          } // lib.optionalAttrs (v?free) {
            inherit (v) free;
          } // lib.optionalAttrs (v?fullName) {
            inherit (v) fullName;
          } // lib.optionalAttrs (v?url) {
            inherit (v) url;
          }) (scope.licenses or lib.licenses);

          maintainerMapping = lib.mapAttrs' (_n: v:
            lib.nameValuePair (toString v.githubId) ({
              inherit (v) github name;
            } // lib.optionalAttrs (v?email) {
              inherit (v) email;
            } // lib.optionalAttrs (v?matrix) {
              inherit (v) matrix;
            })
          ) (scope.maintainers or lib.maintainers);

          # ideally we would use the access name like lib.teams.c3d2 but we cannot get that back from meta.teams
          # and searching for it is expensive
          teamMapping = lib.mapAttrs' (_n: v: lib.nameValuePair v.shortName {
            inherit (v) scope; members = map (m: m.githubId) v.members;
          }) (scope.teams or lib.teams);
        } // lib.optionalAttrs (scope?optionsPrefix) { inherit (scope) optionsPrefix; }
        // lib.optionalAttrs (scope?optionsJSON || scope?modules) {
          optionsJson = scope.optionsJSON or (mkOptionsJSON {
            modules = scope.modules or (throw "A scope requires either optionsJSON or module!");
            specialArgs = scope.specialArgs or { };
            overrideEvalModulesArgs = scope.overrideEvalModulesArgs or { };
          });
        } // (if scope?packagesJSONs then {
          packagesJsons = scope.packagesJSONs;
        } else lib.optionalAttrs (scope?pkgs) {
          packagesJsons = [ (pkgs.writers.writeJSON "${scope.name}-packages.json" (let
            inherit (scope) pkgs;
          in buildPackages pkgs (listPackages [ ] pkgs))) ];
        }))
        scopes;
    in
    runCommand "search-meta"
      {
        config = builtins.toJSON config;
        passAsFile = [ "config" ];
        nativeBuildInputs = [ ixxPkgs.ixx ];
        passthru = { inherit config; };
      }
      ''
        mkdir -p $out/{options,packages}
        ixx index \
          --options-index-output $out/options/index.ixx \
          --options-chunks-output $out/options/chunks \
          --packages-index-output $out/packages/index.ixx \
          --packages-chunks-output $out/packages/chunks \
          --meta-output $out/meta.json \
          --chunk-size ${builtins.toString chunkSize} \
          $configPath
      '');

  # also update README examples
  mkMultiSearch = { scopes, baseHref ? "/", title ? "NüschtOS Search" }:
    let
      chunkSize = 300;
    in
      nuscht-search {
        config =
        assert lib.assertMsg (lib.hasSuffix "/" baseHref) "baseHref needs a trailing slash";
        assert lib.assertMsg (lib.hasPrefix "/" baseHref) "baseHref needs to start with a slash";
        {
          inherit baseHref title chunkSize;
          dataBase = "${baseHref}data/";
          scopes = map (scope: {
            inherit (scope) name;
            optionsEnabled = scope ? optionsJSON || scope ? modules;
            packagesEnabled = scope ? packagesJSONs || scope ? pkgs;
          }) scopes;
        };
        data = mkSearchData { inherit scopes chunkSize; };
      };

  # also update README examples
  mkSearch = { baseHref ? "/", title ? "NüschtOS Search", ... }@args:
    mkMultiSearch {
      inherit baseHref title;
      scopes = [ (lib.removeAttrs args [ "baseHref" "title" ]) ];
    };
}
