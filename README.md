# NüschtOS Search

Simple and fast static-page NixOS option search

## Deployments

- General collection of community projects <https://search.nüschtos.de>
- All flakes used at C3D2 <https://search.nixos.c3d2.de>
- NixVim <https://nix-community.github.io/nixvim/search>
- Nixidy <https://arnarg.github.io/nixidy/options/search>
- catppuccin/nix <https://nix.catppuccin.com/search/index.html>

## Usage

There are two functions exposeed to build the directory containing the static search:

| Name | Description | Available Options |
|---|---|---|
| `mkMultiSearch` | to build a search with multiple scopes (modules). | `baseHref`, `title` and `scopes` |
| `mkSearch` | is a thin wrapper around `mkMultiSearch` to only use one scope (module). | `modules`, `optionsJSON`, `optionsPrefix`, `urlPrefix`, `baseHref` and `title` |

### Explanation of options

| Name | Description |
|---|---|
| `baseHref` | The directory to where the search is going to be deployed relative to the domain. Defaults to `/`. |
| `title` | The title on the top left. Defaults to `NüschtOS Search`. |
| `modules` | A list of NixOS modules as an attrset or file similar to the `nixosSystem` function. Exclusive with `optionsJSON`. |
| `optionsJSON` | Path to a pre-generated `options.json` file. Exclusive with `modules`. |
| `optionsPrefix` | A static prefix to append to all options. An extra `dot` is always appended. Defaults to being empty. |
| `urlPrefix` | The prefix which is prepended to the declaration link. This is usually a link to a git. |
| `scopes` | is a list of attributes which each takes `name`, `modules`, `optionsJSON`, `optionsPrefix` or `urlPrefix` option. |

### Examples5

```nix
mkMultiSearch {4
  baseHref = "/search/";
  title = "Custom Search";
  scopes = [ {3
    name = "NixOS Modules";
    modules = [ self.inputs.nixos-modules.nixosModule ];
    urlPrefix = "https://github.com/NuschtOS/nixos-modules/blob/main/";2
  } {
    name = "Example Module";
    optionsJSON = ./path/to/options.json;1
    optionsPrefix = "programs.example";
    urlPrefix = "https://git.example.com/blob/main/";
    specialArgs = {
      custom = "foo";
    };
    overrideEvalModulesArgs = {
      class = "nixos";
    };
  } ];
};
```

```nix
mkSearch {
  modules = [ self.inputs.nixos-modules.nixosModule ];
  urlPrefix = "https://github.com/NuschtOS/nixos-modules/blob/main/";
}
```

```nix
mkSearch {
  optionsJSON = ./path/to/options.json;
  optionsPrefix = "programs.example";
  urlPrefix = "https://git.example.com/blob/main/";
}
```

```nix
mkSearch {
  optionsJSON = ./path/to/options.json;
  urlPrefix = "https://git.example.com/blob/main/";
  baseHref = "/search/";
  title = "Custom Search";
}
```

- Static page with GitHub Actions and Cloudflare/GitHub Pages <br/>
  <https://github.com/NuschtOS/search.nuschtos.de/blob/main/.github/workflows/gh-pages.yaml> <br/>
  <https://github.com/NuschtOS/search.nuschtos.de/blob/main/flake.nix>

- Deployed with NixOS <br/>
  <https://gitea.c3d2.de/c3d2/nix-config/src/branch/master/hosts/nixos-misc/default.nix#L50-L148>

## Motivation

We wanted something similar to https://search.nixos.org to easily search through all the flakes options across many projects we accumulated in projects
but without the need to deploy an Elasticsearch. Ideally it should be just a static site with json blob that can be deployed on GitHub pages.

## FAQ

### Missing declaration

This is most often caused by using nix' `import` keyword to load a module in the flake instead of referencing it via the path type.
This causes the module system to no longer be aware of the origin of the module and the missing declaration.

- If no arguments are being hand over, this can be easily fixed by removing the `import` keyword. (e.g. [change in sops-nix](https://github.com/Mic92/sops-nix/pull/645))
- If arguments are being hand over, the module needs to be slightly refactored.
- It is often the easiest to move everything depending on the arguments into the `flake.nix` and loading the module via the module systems `imports` variable. (e.g. [change in ifstate.nix](https://codeberg.org/m4rc3l/ifstate.nix/pulls/9))

### default/example is a string/has extra surrounding quotes

This is caused by a missing `lib.literalExpression` in default/example. Please open a pull request against the source of that option to fix this.

### Eval Errors

Sometimes default values are computed. As the required input data is typically not available, `defaultText` should be used. (e.g. [change in nixos-hardware](https://github.com/NixOS/nixos-hardware/pull/1343))

## Debugging `options.json`

Generating a `options.json` in a `nix repl` can be done with the following snippet:

```nix
:b (pkgs.nixosOptionsDoc { inherit ((lib.evalModules { modules = [ { config._module.check = false; } outputs.nixosModules.default ]; })) options; warningsAreErrors = false; }).optionsJSON
```

It is assumed that the flake was loaded before with `:lf` and the module(s) is/are under `nixosModules.default`. For some flakes this may need to be adapted.

## Contact

For bugs and issues please open an issue in this repository.

If you want to chat about things or have ideas, feel free to join the [Matrix chat](https://matrix.to/#/#nuschtos:c3d2.de).

## License

Licensed under MIT license ([LICENSE](LICENSE) or <http://opensource.org/licenses/MIT>).

