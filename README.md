# NüschtOS Search

Simple and fast static-page NixOS option search

## Deployments

- General collection of community projects <https://search.nüschtos.de>
- All flakes used at C3D2 <https://search.nixos.c3d2.de>
- NixVim <https://nix-community.github.io/nixvim/search>
- Nixidy <https://arnarg.github.io/nixidy/options/search>

## How to use

Until we have written proper instructions please take a look at the following examples:
- Static page with GitHub Actions and Cloudflare/GitHub Pages https://github.com/NuschtOS/search.nuschtos.de/blob/main/.github/workflows/gh-pages.yaml https://github.com/NuschtOS/search.nuschtos.de/blob/main/flake.nix
- Deployed with NixOS https://gitea.c3d2.de/c3d2/nix-config/src/branch/master/hosts/nixos-misc/default.nix#L48-L103

## Motivation

We wanted something similar to https://search.nixos.org to easily search through all the flakes options across many projects we accumulated in projects
but without the need to deploy an Elasticsearch. Ideally it should be just a static site with json blob that can be deployed on GitHub pages.

## FAQ

### Missing declaration

This is most often caused by using nix' `import` keyword to load a module in the flake instead of referenceing it via the path type.
This causes the module system to no longer be aware of the origin of the module and the missing declaration.

If no arguments are being hand over, this can be easily fixed by removing the `import` keyword. (e.g. [change in sops-nix](https://github.com/Mic92/sops-nix/pull/645))
If arguements are being hand over, the module needs to be slightly refactored.
It is often the easiest to move everything depending on the arguments into the `flake.nix` and loading the module via the module systems `imports` variable. (e.g. [change in ifstate.nix](https://codeberg.org/m4rc3l/ifstate.nix/pulls/9))

### default/example is a string/has extra surrounding quotes

This is caused by a missing `lib.literalExpression` in default/example. Please open a pull request against the source of that option to fix this.

## Debugging `options.json`

Generating a `options.json` in a `nix repl` can be done with the following snippet:

```
:b (pkgs.nixosOptionsDoc { inherit ((lib.evalModules { modules = [ { config._module.check = false; } outputs.nixosModules.default ]; })) options; warningsAreErrors = false; }).optionsJSON
```

It is assumed that the flake was loaded before with `:lf` and the module(s) is/are under `nixosModules.default`. For some flakes this may need to be adapted.

## Contact

For bugs and issues please open an issue in this repository.

If you want to chat about things or have ideas, feel free to join the [Matrix chat](https://matrix.to/#/#nuschtos:c3d2.de).
