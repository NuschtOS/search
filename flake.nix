{
  description = "Simple and fast static-page NixOS option search";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = (import nixpkgs) {
            inherit system;
          };
        in
        {
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nodejs
              pnpm
              (python3.withPackages (ps: with ps; [ markdown pygments ]))
            ];
          };

          packages = rec {
            nuscht-search = pkgs.callPackage ./nix/frontend.nix { };
            inherit (pkgs.callPackages ./nix/wrapper.nix { inherit nuscht-search; }) mkOptionsJSON mkSearchJSON mkSearch mkMultiSearch;
            default = nuscht-search;
          };
        }
      );
}
