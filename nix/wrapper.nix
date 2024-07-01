{ lib, nixosOptionsDoc, jq, nuscht-search, python3, runCommand, xorg }:

rec {
  mkOptionsJSON = modules:
    let
      patchedModules = [ { config._module.check = false; } ] ++ modules;
      inherit (lib.evalModules { modules = patchedModules; }) options;
    in
    (nixosOptionsDoc {
      options = lib.filterAttrs (key: _: key != "_module") options;
      warningsAreErrors = false;
    }).optionsJSON + /share/doc/nixos/options.json;

  mkSearchJSON = searchArgs:
    let
      optionsJSON = opt: opt.optionsJSON or (mkOptionsJSON opt.modules);
      optionsJSONPrefixed = opt: if opt?optionsJSON then (runCommand "options.json-prefixed" {
        nativeBuildInputs = [ jq ];
      } ''
        mkdir $out
        jq -r 'with_entries(.key as $key | .key |= "${opt.optionsPrefix}.\($key)")' ${optionsJSON opt} > $out/options.json
      '') + /options.json else optionsJSON opt;
    in
    runCommand "options.json"
      { nativeBuildInputs = [ (python3.withPackages (ps: with ps; [ markdown pygments ])) ]; }
      (''
        mkdir $out
        python \
          ${./fixup-options.py} \
      '' + lib.concatStringsSep " " (lib.flatten (map (opt: [
        (optionsJSONPrefixed opt) "'${opt.urlPrefix}'"
        ]) searchArgs)) + ''
          > $out/options.json
      '');

  mkSearch = { modules ? null, optionsJSON ? null, urlPrefix } @ args:
    runCommand "nuscht-search"
      { nativeBuildInputs = [ xorg.lndir ]; }
      ''
        mkdir $out
        lndir ${nuscht-search} $out
        ln -s ${mkSearchJSON [ args ]} $out/options.json
      '';

  # mkMultiSearch [
  #   { modules = [ self.inputs.nixos-modules.nixosModule ]; urlPrefix = "https://github.com/NuschtOS/nixos-modules/blob/main/"; }
  #   { optionsJSON = ./path/to/options.json; optionsPrefix = "programs.example"; urlPrefix = "https://git.example.com/blob/main/"; }
  # ]
  mkMultiSearch = searchArgs:
    runCommand "nuscht-search"
      { nativeBuildInputs = [ xorg.lndir ]; }
      ''
        mkdir $out
        lndir ${nuscht-search} $out
        ln -s ${mkSearchJSON searchArgs}/options.json $out/options.json
      '';
}
