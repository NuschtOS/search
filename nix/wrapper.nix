{ lib, nixosOptionsDoc, nuscht-search, ixxPkgs, runCommand, xorg }:

rec {
  mkOptionsJSON = { modules, specialArgs }: (nixosOptionsDoc {
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
  }).optionsJSON + /share/doc/nixos/options.json;

  mkSearchData = scopes:
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
      '';

  # mkMultiSearch {
  #   baseHref = "/search/";
  #   title = "Custom Search";
  #   scopes = [
  #     { modules = [ self.inputs.nixos-modules.nixosModule ]; urlPrefix = "https://github.com/NuschtOS/nixos-modules/blob/main/"; name = "NixOS Modules"; }
  #     { optionsJSON = ./path/to/options.json; optionsPrefix = "programs.example"; urlPrefix = "https://git.example.com/blob/main/"; name = "Example Module"; }
  #   ];
  # };
  mkMultiSearch = { scopes, baseHref ? "/", title ? "NüschtOS Search" }:
    runCommand "nuscht-search"
      { nativeBuildInputs = [ xorg.lndir ]; }
      ''
        mkdir $out
        lndir ${nuscht-search.override { inherit baseHref title; }} $out
        ln -s ${mkSearchData scopes}/{meta,index.ixx} $out
      '';

  # mkSearch { modules = [ self.inputs.nixos-modules.nixosModule ]; urlPrefix = "https://github.com/NuschtOS/nixos-modules/blob/main/"; }
  # mkSearch { optionsJSON = ./path/to/options.json; optionsPrefix = "programs.example"; urlPrefix = "https://git.example.com/blob/main/"; }
  # mkSearch { optionsJSON = ./path/to/options.json; urlPrefix = "https://git.example.com/blob/main/"; baseHref = "/search/"; title = "Custom Search"; }
  mkSearch = { baseHref ? "/", title ? "NüschtOS Search", ... }@args:
    mkMultiSearch {
      inherit baseHref title;
      scopes = [ (lib.removeAttrs args [ "baseHref" "title" ]) ];
    };
}
