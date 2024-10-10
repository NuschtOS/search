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
            nativeBuildInputs = with pkgs; [
              nodejs
              pnpm
              (python3.withPackages (ps: with ps; [ markdown pygments ]))

              cargo
              clippy
              rustc
              rustc.llvmPackages.lld
              wasm-pack
            ];

            RUST_SRC_PATH = pkgs.rust.packages.stable.rustPlatform.rustLibSrc;
          };

          packages = rec {
            nuscht-search = pkgs.callPackage ./nix/frontend.nix { };
            inherit (pkgs.callPackages ./nix/wrapper.nix { inherit nuscht-search; }) mkOptionsJSON mkSearchJSON mkSearch mkMultiSearch;
            default = nuscht-search;
          };
        }
      );
}
