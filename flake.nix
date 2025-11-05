{
  description = "Simple and fast static-page NixOS option search";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/cebe312dcfefde35f93532584701cc5fa9c1f236";
    flake-utils.url = "github:numtide/flake-utils";
    ixx = {
      # match version with npm package
      url = "github:NuschtOS/ixx/packages";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { nixpkgs, flake-utils, ixx, self, ... }:
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
              http-server
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
                inherit self ixxPkgs;
                nuscht-search = nuscht-search-unwrapped;
              }) mkOptionsJSON mkPackagesJSON mkSearchJSON mkSearch mkMultiSearch;
              nixpkgs-search = mkSearch {
                optionsJSON = (import "${nixpkgs}/nixos/release.nix" { }).options + /share/doc/nixos/options.json;
                name = "NixOS";
                urlPrefix = "https://github.com/NixOS/nixpkgs/tree/master/";
                pkgs = pkgs.writeText "pkgs.nix" /* nix */ ''
                  (import ${nixpkgs}) {
                    system = "x86_64-linux";
                    config.allowBroken = true;
                  }
                '';
              };
              default = nixpkgs-search;
            };
        }
      ) // { inherit self; };
}
