{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      # url = "github:nix-community/home-manager";
      # https://github.com/nix-community/home-manager/pull/5942
      url = "github:SuperSandro2000/home-manager/nuschtos-search-options-json";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    search = {
      # use --override-input search ..
      url = "path:../.";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    nixos-modules = {
      url = "github:nuschtos/nixos-modules";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        search.follows = "search";
        flake-utils.follows = "flake-utils";
      };
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = { nixpkgs, flake-utils, home-manager, search, nixos-modules, nixvim, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = (import nixpkgs) {
            inherit system;
          };
        in
        {
          packages = {
            default = search.packages.${system}.mkMultiSearch {
              scopes = [
                {
                  optionsJSON = home-manager.packages.${system}.docs-html.passthru.home-manager-options.nixos + /share/doc/nixos/options.json;
                  urlPrefix = "https://github.com/nix-community/home-manager/tree/master/";
                }
                {
                  optionsJSON = home-manager.packages.${system}.docs-json + /share/doc/home-manager/options.json;
                  optionsPrefix = "home-manager.users.<name>";
                  urlPrefix = "https://github.com/nix-community/nixvim/tree/main/";
                }
                {
                  modules = [
                    ({ config, lib, ... }: {
                      _module.args = {
                        libS = nixos-modules.lib { inherit config lib; };
                        inherit pkgs;
                      };
                      imports = [ (pkgs.path + "/nixos/modules/misc/extra-arguments.nix") ];
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
          };
        });
}
