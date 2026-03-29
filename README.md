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
    checks.x86-64_linux.dependency-graph = weeder-nix.lib.x86_64-linux.makeWeederCheck {
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
(This does the `addHieOutput` and `buildTestsWithoutRunning` handling for you.)

Arguments:

* `name`: Name of the check derivation
* `weederToml`: Path to the `weeder.toml` configuration file.
* `packages`: List of package names to make the check for.
* `haskellPackages`: `haskellPackages` to get those packages from.
* `reportOnly`: Don't fail if weeds are found, but instead succeed and create a report of the weeds instead.
* `extraArgs`: Extra command-line arguments for the `weeder` invocation.

See `./nix/weederCheckFor.nix` for the available arguments.

### `weederCheckFor`

Make a weeder check based on raw packages.
This assumes you've used something like `addHieOutput`.
You probably don't need to use this.

See `./nix/weederCheckFor.nix`.

### `addHieOutput`

Add a `.hie` output to a Haskell package.
This adds `-fwrite-ide-info` and collects the resulting `.hie` files into a separate output.
You probably don't need to use this directly; `makeWeederCheck` does it for you.

See `./nix/addHieOutput.nix`.

### `buildTestsWithoutRunning`

Build test code without running the test suite.

Cabal doesn't build testing code unless tests are turned on.
This function enables `doCheck` (so test code is compiled and test dependencies are available)
but sets `checkPhase` to `""` so the test suite is not executed.

This is useful when you want `.hie` files for test code (for weeder)
without paying the cost of running the tests.

If you apply `addHieOutput` to your packages yourself (instead of using `makeWeederCheck`),
you can use this function to compile test code without running it:

```nix
myPackage = buildTestsWithoutRunning (addHieOutput haskellPackages.myPackage);
```

See `./nix/buildTestsWithoutRunning.nix`.

### `disableOptimisation`

Disable optimisation for a Haskell package.

Weeder only needs `.hie` files, so there is no point spending time on optimisation.
This function adds `-O0`, `-fignore-interface-pragmas`, and `-fomit-interface-pragmas`.
`makeWeederCheck` applies this automatically.

See `./nix/disableOptimisation.nix`.
