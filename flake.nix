{
  description = "Simple and fast static-page NixOS option search";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ixx = {
      # match version with npm package
      url = "github:NuschtOS/ixx/v0.0.6";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs =
    { nixpkgs, ixx, ... }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = lib.genAttrs systems;
      nixpkgsFor = nixpkgs.legacyPackages;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              nodejs
              pnpm
              ixxPkgs.ixx
            ];
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          ixxPkgs = ixx.packages.${system};
        in
        rec {
          nuscht-search = pkgs.callPackage ./nix/frontend.nix { };
          inherit (pkgs.callPackages ./nix/wrapper.nix { inherit ixxPkgs nuscht-search; })
            mkOptionsJSON
            mkSearchJSON
            mkSearch
            mkMultiSearch
            ;
          default = nuscht-search;
        }
      );
    };
}
