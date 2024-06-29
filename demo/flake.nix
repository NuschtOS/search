{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    search = {
      # use --override-input search ..
      url = "path:../.";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    nixos-modules = {
      url = "github:nuschtos/nixos-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, flake-utils, search, nixos-modules, nixvim, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = (import nixpkgs) {
            inherit system;
          };
        in
        {
          packages = {
            default = search.packages.${system}.mkMultiSearch [
              {
                modules = [
                  ({ config, lib, ... }: {
                    _module.args = {
                      libS = nixos-modules.lib { inherit config lib; };
                      inherit pkgs;
                    };
                  })
                  nixos-modules.nixosModule
                ];
                urlPrefix = "https://github.com/NuschtOS/nixos-modules/tree/main/";
              }
              {
                optionsJSON = nixvim.packages.${system}.options-json + /share/doc/nixos/options.json;
                optionsPrefix = "programs.nixvim";
                urlPrefix = "https://github.com/nix-community/nixvim/tree/main/";
              }
            ];
          };
        });
}
