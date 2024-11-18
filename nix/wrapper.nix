{ ixxPkgs, lib, nuscht-search, pkgs }:

rec {
  mkOptionsJSON = pkgs.callPackage ({ modules, specialArgs, nixosOptionsDoc }: (nixosOptionsDoc {
    inherit ((lib.evalModules {
      modules = modules ++ [
        ({ lib, ... }: {
          options._module.args = lib.mkOption {
            internal = true;
          };
          config._module.check = false;
        })
      ];
      inherit specialArgs;
    })) options;
    warningsAreErrors = false;
  }).optionsJSON + /share/doc/nixos/options.json);

  mkSearchData = pkgs.callPackage ({ scopes, runCommand }:
    let
      config.scopes = map (scope: {
        inherit (scope) urlPrefix;
      } // lib.optionalAttrs (scope?name) { inherit (scope) name; }
        // lib.optionalAttrs (scope?optionsPrefix) { inherit (scope) optionsPrefix; }
        // {
        optionsJson = scope.optionsJSON or (mkOptionsJSON {
          modules = scope.modules or (throw "A scope requires either optionsJSON or module!");
          specialArgs = scope.specialArgs or { };
        });
      }) scopes;
    in
    runCommand "search-meta"
      {
        config = builtins.toJSON config;
        passAsFile = [ "config" ];
        nativeBuildInputs = [ ixxPkgs.ixx ];
      }
      ''
        mkdir $out
        ixx index \
          --index-output $out/index.ixx \
          --meta-output $out/meta \
          --chunk-size 500 \
          $configPath
      '');

  # also update README examples
  mkMultiSearch = pkgs.callPackage ({ scopes, baseHref ? "/", title ? "NüschtOS Search", runCommand, xorg }:
    runCommand "nuscht-search" {
      nativeBuildInputs = [ xorg.lndir ];
    } ''
      mkdir $out
      lndir ${nuscht-search.override { inherit baseHref title; }} $out
      ln -s ${mkSearchData { inherit scopes; }}/{meta,index.ixx} $out
    '');

  # also update README examples
  mkSearch = pkgs.callPackage ({ baseHref ? "/", title ? "NüschtOS Search", ... }@args:
    mkMultiSearch {
      inherit baseHref title;
      scopes = [ (lib.removeAttrs args [ "baseHref" "title" ]) ];
    });
}
