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

  mkPackagesJSON = { name, pkgs }:
    pkgs.writeText name (
      builtins.toJSON (
        lib.mapAttrsToList
          (name: value:
            let
              evalResult = builtins.tryEval value;
            in
            {
              attrName = name;
            } // (
              if evalResult.success && evalResult.value ? name then
                (
                  { inherit (evalResult.value) name; }
                  // lib.optionalAttrs (evalResult.value? pname) { inherit (evalResult.value) pname; }
                  # toString because of fetchpatch and fetchpatch2
                  // lib.optionalAttrs (evalResult.value? version) { version = toString evalResult.value.version; }
                  // lib.optionalAttrs (evalResult.value? outputs) { inherit (evalResult.value) outputs; }
                  // lib.optionalAttrs (evalResult.value? meta)
                    (
                      lib.optionalAttrs (evalResult.value.meta? description) { inherit (evalResult.value.meta) description; }
                      // lib.optionalAttrs (evalResult.value.meta?homepage) { inherit (evalResult.value.meta) homepage; }
                      // lib.optionalAttrs (evalResult.value.meta?broken) { inherit (evalResult.value.meta) broken; }
                      // lib.optionalAttrs (evalResult.value.meta?license) { inherit (evalResult.value.meta) license; }
                      // lib.optionalAttrs (evalResult.value.meta?insecure) { inherit (evalResult.value.meta) insecure; }
                      // lib.optionalAttrs (evalResult.value.meta?maintainers) { inherit (evalResult.value.meta) maintainers; }
                      // lib.optionalAttrs (evalResult.value.meta?unfree) { inherit (evalResult.value.meta) unfree; }
                    )
                )
              else { evalError = true; }
            )
          )
          pkgs
      )
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
