{
  description = "Simple and fast static-page NixOS option search";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    ixx = {
      # match version with npm package
      # TODO: update with v0.0.5
      url = "github:NuschtOS/ixx";
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

          packages = rec {
            nuscht-search = pkgs.callPackage ./nix/frontend.nix { };
            inherit (pkgs.callPackages ./nix/wrapper.nix { inherit nuscht-search ixxPkgs; }) mkOptionsJSON mkSearchJSON mkSearch mkMultiSearch;
            default = nuscht-search;
          };
        }
      );
}
