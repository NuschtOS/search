{
  description = "Simple and fast static-page NixOS option search";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    ixx = {
      # match version with npm package
      url = "github:NuschtOS/ixx/v0.1.0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { nixpkgs, flake-utils, ixx, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = (import nixpkgs) {
            inherit system;
          };
          ixxPkgs = ixx.packages.${system};
        in
        {
          devShells.default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              nodejs
              pnpm
              ixxPkgs.ixx
            ];
          };

          packages =
            let
              nuscht-search-unwrapped = pkgs.callPackage ./nix/frontend.nix { };
            in
            rec {
              inherit (pkgs.callPackages ./nix/wrapper.nix {
                inherit ixxPkgs;
                nuscht-search = nuscht-search-unwrapped;
              }) mkOptionsJSON mkSearchJSON mkSearch mkMultiSearch;
              nixpkgs-search = mkSearch {
                optionsJSON = (import "${nixpkgs}/nixos/release.nix" { }).options + /share/doc/nixos/options.json;
                name = "NixOS";
                urlPrefix = "https://github.com/NixOS/nixpkgs/tree/master/";
              };
              default = nixpkgs-search;
            };
        }
      );
}
