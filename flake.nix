{
  description = "Simple and fast static-page NixOS option and packages search";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    ixx = {
      # match version with npm package
      url = "github:NuschtOS/ixx/v0.2.3";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NuschtOS/nuschtpkgs/nixos-unstable";
  };

  outputs = { flake-utils, ixx, nix-index-database, nixpkgs, self, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = (import nixpkgs) {
            inherit system;
          };
          inherit (pkgs) lib;
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

            env = {
              PLAYWRIGHT_BROWSERS_PATH = pkgs.playwright-driver.browsers;
            };

            shellHook = ''
              pnpm install -D @nuschtos/fixx@$(sed -nE 's/.*github:NuschtOS\/ixx\/v([0-9]\.[0-9]\.[0-9]).*/\1/p' flake.nix)
              pnpm install -D @playwright/test@${pkgs.playwright-driver.version}
            '';
          };

          packages =
            let
              nuscht-search-unwrapped = pkgs.callPackage ./nix/frontend.nix { };
            in
            rec {
              fixx-dist = ixxPkgs.fixx.dist;
              fixx-dist-debug = (ixxPkgs.fixx.override { release = false; }).dist;

              inherit (pkgs.callPackages ./nix/wrapper.nix {
                inherit self ixxPkgs;
                inherit (nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}) nix-index-database;
                nuscht-search = nuscht-search-unwrapped;
              }) mkOptionsJSON mkPackagesJSONs mkCollectManDerivations mkSearchData mkMultiSearch mkSearch;

              nixpkgs-search = mkSearch (
                # nixos/release.nix hardcodes a pkgs import with x86_64-linux system
                lib.optionalAttrs (system == "x86_64-linux")
                  {
                    optionsJSON = (import "${nixpkgs}/nixos/release.nix" { }).options + /share/doc/nixos/options.json;
                  } // {
                  name = "NixOS";
                  urlPrefix = "https://github.com/NixOS/nixpkgs/tree/master/";
                  packagesJSONs = mkPackagesJSONs {
                    name = "nixpkgs";
                    pkgs = pkgs.writeText "pkgs.nix" /* nix */ ''
                      (import ${nixpkgs}) {
                        system = "${pkgs.stdenv.hostPlatform.system}";
                        config = {
                          allowBroken = true;
                          allowSrcEvalForDrvMeta = true;
                        };
                      }
                    '';
                  };
                }
              );
              default = nixpkgs-search;
            };
        }
      ) // { inherit self; };
}
