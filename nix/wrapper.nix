{ lib, nixosOptionsDoc, runCommand, python3, xorg, nuscht-search, ... }:

rec {
  mkOptionsJSON = modules:
    let
      patchedModules = lib.singleton { config._module.check = false; } ++ modules;
      inherit (lib.evalModules { modules = patchedModules; }) options;
    in
    nixosOptionsDoc {
      options = lib.filterAttrs (key: _: key != "_module") options;
      warningsAreErrors = false;
    };

  mkSearchJSON = { modules, urlPrefix }:
    runCommand "options.json"
      { nativeBuildInputs = [ (python3.withPackages (ps: with ps; [ markdown pygments ])) ]; }
      ''
        mkdir $out
        python \
          ${./fixup-options.py} \
          ${(mkOptionsJSON modules).optionsJSON}/share/doc/nixos/options.json \
          '${urlPrefix}' \
          > $out/options.json
      '';

  mkSearch = { modules, urlPrefix }:
    runCommand "nuscht-search"
      { nativeBuildInputs = [ xorg.lndir ]; }
      ''
        mkdir $out
        lndir ${nuscht-search} $out
        ln -s ${mkSearchJSON { inherit modules urlPrefix; }} $out/options.json
      '';
}
