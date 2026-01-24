{ lib }:

let
  shouldRemoved = attrPrefix: name: value:
    attrPrefix != [ ]
    && builtins.elemAt attrPrefix (builtins.length attrPrefix - 1) == name
    # TODO: re-enable when https://github.com/NixOS/nixpkgs/pull/437723#issuecomment-3493948379 is resolved
    || name == "tests"
    # we are not noogle, yet
    || name == "lib"
    # accesses builtins.currentSystem unconditionally
    || name == "vm-variant"
    # formatter types
    || name == "functor"
    # avoid infinite recursions when traversing package sets
    || name == "pkgs"
    # override infrastructure
    || name == "override" || name == "__functionArgs" || name == "__functor" || name == "overrideDerivation"
    # cross-compilation infrastructure
    || name == "__splicedPackages" || name == "buildPackages"
    # haskell adds all packages to buildHaskellPackages again
    || name == "buildHaskellPackages"
    # another variant of all haskell packages
    || (attrPrefix == [ "haskell" "packages" ] && name == "native-bignum")
    # we don't need head...
    || name == "ghcHEAD"
    # ... or binary variants
    || (lib.hasPrefix "ghc" name && lib.hasSuffix "Binary" name)
    # has broken meta stuff
    || (lib.hasPrefix "coqPackages" name)
    # qt exposes sources under srcs
    || name == "srcs"
    # broken since buildPython* supports "finalAttrs"-pattern
    || attrPrefix == [ "pypy27Packages" ] || attrPrefix == [ "pypy27Packages" ] || attrPrefix == ["pypy2Packages"] || attrPrefix == ["pypyPackages"] || attrPrefix == ["python27Packages"] || attrPrefix == ["python2Packages"]
    # don't recurse into pythonPackages a nth time and just assume and attrPrefix ending in Packages (eg. python311Packages or mopidyPackages) is not what we want
    || (attrPrefix != [ ] && lib.hasSuffix "Packages" (lib.head attrPrefix) && name == "pythonPackages")
    || !(builtins.isAttrs value);

  listPackages = attrPrefix: pkgs:
    let
      pkgsAndPkgSets = lib.filterAttrs (name: value: !(builtins.tryEval (shouldRemoved attrPrefix name value)).value) pkgs;
      rawPkgNames = builtins.attrNames (lib.filterAttrs (_name: value: !(builtins.tryEval (!(lib.isDerivation value))).value) pkgsAndPkgSets);
    in
    (
      let
        finalPkgs = map (name: attrPrefix ++ [ name ]) rawPkgNames;
      in
      finalPkgs
    ) ++ (
      let
        finalPkgs =
          let
            pkgSets = lib.filterAttrs (name: value: !(builtins.elem name rawPkgNames) && !(builtins.tryEval (builtins.hasAttr "AAAAAASomeThingsFailToEvaluate" value)).value) pkgsAndPkgSets;
          in
          lib.mapAttrs (name: value: listPackages (attrPrefix ++ [ name ]) value) pkgSets;
      in
      builtins.concatMap (x: x) (builtins.attrValues finalPkgs)
    );
in
{
  inherit listPackages;
}
