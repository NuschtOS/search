{ lib, listPackages, pkgs, self }:

let
  nixpkgsPkgs = pkgs;
in
{
  mkPackagesJSONs = { name, pkgs }:
    let
      partitionPackageNames = pkgNames:
        builtins.groupBy
          (name:
            let
              last = builtins.head (lib.sublist (builtins.length name - 1) 1 name);
            in
            # this also works if `last` has only one character
            lib.toLower (builtins.substring 0 1 last)
          )
          pkgNames;

      list = listPackages [ ] (import pkgs);

      partedList = partitionPackageNames list;
    in
    lib.mapAttrsToList
      (part: attrNames:
        nixpkgsPkgs.runCommand "${name}-${part}.json"
          {
            partition = builtins.toJSON attrNames;
            passAsFile = [ "partition" ];
            nativeBuildInputs = with nixpkgsPkgs; [ jq nixVersions.nix_2_33 ];
          }
          ''
            cp ${./build-packages.nix} build-packages.nix
            jq . $partitionPath > partition.json
            cp ${pkgs} pkgs.nix
            echo "Building $name"
            NIX_STATE_DIR=$TMPDIR NIX_PATH= nix \
              --extra-experimental-features flakes,nix-command \
              eval \
              --impure \
              --json \
              --offline \
              --quiet \
              --read-only \
              --show-trace \
              --expr \
              '(import ./build-packages.nix { inherit (import ${self.inputs.nixpkgs} {}) lib; }).buildPackages (import ./pkgs.nix) (builtins.fromJSON (builtins.readFile ./partition.json))' \
              | jq . > $out
            echo "Done $name"
          '')
      partedList;
}
