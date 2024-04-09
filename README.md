# Weeder Nix

Produce a weeder check for a list of Haskell Packages from Nix

## Quick Start

Add this repository as a flake:

``` nix
{
  inputs = {
    weeder-nix.url = "github:NorfairKing/weeder-nix";
  };
}
```

Make a weeder check

``` nix
{
  outputs = { self, weeder-nix }: {
    checks.x86-64_linux.dependency-graph = weeder-nix.lib.x86-64_linux.makeWeederCheck {
      haskellPackages = pkgs.haskellPackages;
      packages = [
        "foobar"
        "foobar-gen"
      ];
    };
  };
}
```

## API Reference

### `makeWeederCheck`

Make a weeder check for given Haskell Packages.
(This does the `addHieOutput` handling for you.)

Arguments:

* `name`: Name of the check derivation
* `weederToml`: Path to the `weeder.toml` configuration file.
* `packages`: List of package names to make the check for.
* `haskellPackages`: `haskellPackages` to get those packages from.
* `reportOnly`: Don't fail if weeds are found, but instead succeed and create a report of the weeds instead.
* `extraArgs`: Extra command-line arguments for the `weeder` invocation.

See `./nix/weederCheckFor.nix` for the available arguments.

### `weederCheckScriptFor`

Make a weeder check based on raw packages.
This assumes you've used something like `addHieOutput`.
You probably don't need to use this.

See `./nix/weederCheckFor.nix`.

### `addHieOutput`

Add a `.hie` output to a Haskell package.
You probably don't need to use this.

See `./nix/addHieOutput.nix`.
