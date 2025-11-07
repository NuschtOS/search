{ lib, ... }:

let
  extractLicense = lic:
    if lib.isList lic then
      builtins.foldl'
        (acc: curr: acc ++ (extractLicense curr))
        [ ]
        lic
    else if lib.isAttrs lic then
      [
        (
          lic.shortName or lic.fullName
            # TODO: try to remove after https://github.com/NixOS/nixpkgs/pull/458238 and https://github.com/NixOS/nixpkgs/pull/458240 is merged
            or lic.url
        )
      ]
    else if lib.isString lic then
      [ lic ]
    else
      throw "Don't know how to handle ${toString lic}";

  mkPackage = attrName: derv:
  builtins.trace "${builtins.concatStringsSep "." attrName} ${derv.name}"
    {
      attrName = builtins.concatStringsSep "." attrName;
      inherit (derv) name;
    }
    // lib.optionalAttrs (derv ? pname) { inherit (derv) pname; }
    # toString because of fetchpatch and fetchpatch2
    // lib.optionalAttrs (derv ? version) { version = toString derv.version; }
    // lib.optionalAttrs (derv ? outputs) { inherit (derv) outputs; }
    // lib.optionalAttrs (derv ? meta)
      (
        lib.optionalAttrs (derv.meta ? description) { inherit (derv.meta) description; }
        // lib.optionalAttrs
          (derv.meta ? homepage
          # TODO: remove when https://github.com/NixOS/nixpkgs/pull/458597 is merged
          && derv.meta.homepage != "")
          { inherit (derv.meta) homepage; }
        // lib.optionalAttrs (derv.meta ? broken) { inherit (derv.meta) broken; }
        // lib.optionalAttrs (derv.meta ? license) { licenses = extractLicense derv.meta.license; }
        // lib.optionalAttrs (derv.meta ? licenses) { licenses = extractLicense derv.meta.licenses; }
        // lib.optionalAttrs (derv.meta ? insecure) { inherit (derv.meta) insecure; }
        // lib.optionalAttrs (derv.meta ? maintainers) {
          maintainers = map (m: toString m.githubId) derv.meta.maintainers;
        }
        // lib.optionalAttrs (derv.meta ? teams) {
          teams = map (m: m.shortName) derv.meta.teams;
        }
        // lib.optionalAttrs (derv.meta ? unfree) { inherit (derv.meta) unfree; }
        // lib.optionalAttrs (derv.meta ? position) { declaration = derv.meta.position; }
      );

  createEvalError = newName: {
    attrName = builtins.concatStringsSep "." newName;
    evalError = true;
  };

  pkgs = import ./pkgs.nix;
in
map
  (attrName:
  let
    derv = lib.getAttrFromPath attrName pkgs;
    pkg = mkPackage attrName derv;
    # tryEval (deepSeq ...) makes sure we catch all potential throws in all attributes early on
    # NOTE: running deepSeq on any derivation results in an infinite recursion due to stdenv.passthru generating a warning
    pkgEvalResult = builtins.tryEval (builtins.deepSeq pkg pkg);
  in
  if pkgEvalResult.success then
    pkgEvalResult.value
  else
    createEvalError attrName
  )
  (builtins.fromJSON (builtins.readFile ./partition.json))

