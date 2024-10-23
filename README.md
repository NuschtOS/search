# NüschtOS Search

Simple and fast static-page NixOS option search

## Deployments

- NixOS Modules <https://modules.nüschtos.de>
- General collection of community projects <https://search.nüschtos.de>
- NixVim <https://nix-community.github.io/nixvim/search>

## How to use

Until we have written proper instructions please take a look at the following examples:
- Static page with GitHub Actions and Cloudflare/GitHub Pages https://github.com/NuschtOS/search.nuschtos.de/blob/main/.github/workflows/gh-pages.yaml https://github.com/NuschtOS/search.nuschtos.de/blob/main/flake.nix
- Deployed with NixOS https://gitea.c3d2.de/c3d2/nix-config/src/branch/master/hosts/nixos-misc/default.nix#L48-L103

## Motivation

We wanted something similar to https://search.nixos.org to easily search through all the flakes options across many projects we accumulated in projects
but without the need to deploy an Elasticsearch. Ideally it should be just a static site with json blob that can be deployed on GitHub pages.

## Debugging

Generating `options.json` in a `nix repl`:

```
:b (pkgs.nixosOptionsDoc { inherit ((lib.evalModules { modules = [ { config._module.check = false; } outputs.nixosModules.default ]; })) options; warningsAreErrors = false; }).optionsJSON
```
