{ lib }:

let
  extractLicense = lic:
    if lib.isList lic then
      builtins.foldl'
        (acc: curr: acc ++ (extractLicense curr))
        [ ]
        lic
    else if lib.isAttrs lic then
      [
        (lic.shortName or lic.fullName or lic.url)
      ]
    else if lib.isString lic then
      [ lic ]
    else
      throw "Don't know how to handle ${toString lic}";

  # test with:
  # nix-repl> :p (import ./nix/build-packages.nix { inherit lib; }).mkPackage [ "test" ] pkgs.nixosTests.geoserver
  mkPackage = attrName: derv: {
    attrName = builtins.concatStringsSep "." attrName;
    inherit (derv) name;
  }
  // lib.optionalAttrs (derv ? pname) { inherit (derv) pname; }
  # toString because of fetchpatch and fetchpatch2
  // lib.optionalAttrs (derv ? version) { version = toString derv.version; }
  // lib.optionalAttrs (derv ? outputs) { inherit (derv) outputs; }
  // lib.optionalAttrs (derv ? disabled) { inherit (derv) disabled; }
  // lib.optionalAttrs (derv ? meta)
    (
      lib.optionalAttrs (derv.meta ? description) { inherit (derv.meta) description; }
      // lib.optionalAttrs (derv.meta ? longDescription) { inherit (derv.meta) longDescription; }
      // lib.optionalAttrs (derv.meta ? homepage) { inherit (derv.meta) homepage; }
      // lib.optionalAttrs (derv.meta ? broken) { inherit (derv.meta) broken; }
      // lib.optionalAttrs (derv.meta ? identifiers) (
        lib.optionalAttrs (derv.meta.identifiers?cpe) { inherit (derv.meta.identifiers) cpe; }
        // lib.optionalAttrs (derv.meta.identifiers?possibleCPEs) { possibleCpes = map (c: c.cpe) derv.meta.identifiers.possibleCPEs; }
        // lib.optionalAttrs (derv.meta.identifiers?purl) { inherit (derv.meta.identifiers) purl; }
      )
      // lib.optionalAttrs (derv.meta ? license) { licenses = extractLicense derv.meta.license; }
      // lib.optionalAttrs (derv.meta ? licenses) { licenses = extractLicense derv.meta.licenses; }
      // lib.optionalAttrs (derv.meta ? knownVulnerabilities) { inherit (derv.meta) knownVulnerabilities; }
      // lib.optionalAttrs (derv.meta ? maintainers) {
        maintainers = map (m: m.githubId)
          (if derv.meta ? teams then
            let
              allTeamMaintainerIds = lib.foldl' (acc: elem: acc ++ map (m: m.githubId) elem.members) [ ] derv.meta.teams;
            in
            lib.filter (m: lib.all (x: x != m.githubId) allTeamMaintainerIds) derv.meta.maintainers
          else
            derv.meta.maintainers
          );
      }
      // lib.optionalAttrs (derv.meta ? teams) {
        teams = map (m: m.shortName or "meta.teams for ${derv.name} is wrong!") derv.meta.teams;
      }
      // lib.optionalAttrs (derv.meta ? position) { declaration = derv.meta.position; }
    );

  createEvalError = newName: {
    attrName = builtins.concatStringsSep "." newName;
    evalError = true;
  };

  pkgs = import ./pkgs.nix;
in
{
  inherit extractLicense mkPackage;

  buildPackages = map
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
    (builtins.fromJSON (builtins.readFile ./partition.json));
}
