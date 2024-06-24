{ lib, nixosOptionsDoc, nuscht-search, python3, runCommand, xorg }:

rec {
  mkOptionsJSON = modules:
    let
      patchedModules = lib.singleton { config._module.check = false; } ++ modules;
      inherit (lib.evalModules { modules = patchedModules; }) options;
    in
    (nixosOptionsDoc {
      options = lib.filterAttrs (key: _: key != "_module") options;
      warningsAreErrors = false;
    }).optionsJSON + /share/doc/nixos/options.json;

  mkSearchJSON = listOfModuleAndUrlPrefix:
    runCommand "options.json"
      { nativeBuildInputs = [ (python3.withPackages (ps: with ps; [ markdown pygments ])) ]; }
      (''
        mkdir $out
        python \
          ${./fixup-options.py} \
      '' + lib.concatStringsSep " " (lib.flatten (map (opt: [
        (mkOptionsJSON opt.modules) "'${opt.urlPrefix}'"
        ]) listOfModuleAndUrlPrefix)) + ''
          > $out/options.json
      '');

  mkSearch = { modules, urlPrefix }:
    runCommand "nuscht-search"
      { nativeBuildInputs = [ xorg.lndir ]; }
      ''
        mkdir $out
        lndir ${nuscht-search} $out
        ln -s ${mkSearchJSON [ { inherit modules urlPrefix; } ]} $out/options.json
      '';

  mkMultiSearch = listOfModuleAndUrlPrefix:
    runCommand "nuscht-search"
      { nativeBuildInputs = [ xorg.lndir ]; }
      ''
        mkdir $out
        lndir ${nuscht-search} $out
        ln -s ${mkSearchJSON listOfModuleAndUrlPrefix}/options.json $out/options.json
      '';
}
