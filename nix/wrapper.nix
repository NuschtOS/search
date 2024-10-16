{ lib, nixosOptionsDoc, jq, nuscht-search, python3, runCommand, xorg }:

rec {
  mkOptionsJSON = modules: (nixosOptionsDoc {
    inherit ((lib.evalModules {
      modules = modules ++ [
        ({ lib, ... }: {
          options._module.args = lib.mkOption {
            internal = true;
          };
          config._module.check = false;
        })
      ];
    })) options;
    warningsAreErrors = false;
  }).optionsJSON + /share/doc/nixos/options.json;

  mkSearchJSON = scopes:
    let
      optionsJSON = opt: opt.optionsJSON or (mkOptionsJSON opt.modules);
      optionsJSONPrefixed = opt:
        if opt?optionsJSON then (runCommand "options.json-prefixed"
          {
            nativeBuildInputs = [ jq ];
          } /* bash */ ''
          mkdir $out
          jq -r '[to_entries[] | select(.key | test("^(_module|_freeformOptions|warnings|assertions|content)\\..*") | not)] | from_entries ${lib.optionalString (opt?optionsPrefix) ''| with_entries(.key as $key | .key |= "${opt.optionsPrefix}.\($key)")''}' ${optionsJSON opt} > $out/options.json
        '') + /options.json else optionsJSON opt;
    in
    runCommand "options.json"
      { nativeBuildInputs = [ (python3.withPackages (ps: with ps; [ markdown pygments html-sanitizer ])) ]; }
      (''
        mkdir $out
        python \
          ${./fixup-options.py} \
      '' + lib.concatStringsSep " " (lib.flatten (map
        (opt: [
          (optionsJSONPrefixed opt)
          "'${opt.urlPrefix}'"
        ])
        scopes)) + ''
        > $out/options.json
      '');

  # mkMultiSearch {
  #   baseHref = "/search/";
  #   title = "Custom Search";
  #   scopes = [
  #     { modules = [ self.inputs.nixos-modules.nixosModule ]; urlPrefix = "https://github.com/NuschtOS/nixos-modules/blob/main/"; }
  #     { optionsJSON = ./path/to/options.json; optionsPrefix = "programs.example"; urlPrefix = "https://git.example.com/blob/main/"; }
  #   ];
  # };
  mkMultiSearch = { scopes, baseHref ? "/", title ? "NüschtOS Search" }:
    runCommand "nuscht-search"
      { nativeBuildInputs = [ xorg.lndir ]; }
      ''
        mkdir $out
        lndir ${nuscht-search.override { inherit baseHref title; }} $out
        ln -s ${mkSearchJSON scopes}/options.json $out/options.json
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
