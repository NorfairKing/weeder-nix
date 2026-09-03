# Weeder Nix

[![NixCI](https://staging.nix-ci.com/badge/gh:NorfairKing:weeder-nix)](https://staging.nix-ci.com/gh:NorfairKing:weeder-nix)

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
(This does the `addHieOutput` handling for you, and the `buildTestsWithoutRunning` handling when `includeTests` is set.)

Arguments:

* `name`: Name of the check derivation
* `weederToml`: Path to the `weeder.toml` configuration file.
* `packages`: List of package names to make the check for.
* `haskellPackages`: `haskellPackages` to get those packages from.
* `reportOnly`: Don't fail if weeds are found, but instead succeed and create a report of the weeds instead.
* `extraArgs`: Extra command-line arguments for the `weeder` invocation.
* `includeTests`: Whether to also feed weeder the `.hie` files of test (and benchmark) code. Defaults to `false`.

  When `false` (the default), weeder only sees non-test code, so code that is used _only_ by tests is reported as a weed.
  That is the point of the default: with the test suite in the graph, dead code that happens to be well-tested looks alive.
  When `true`, the test suite's `.hie` files are included as well, so anything the tests use counts as used.

  Note: with `includeTests = false`, the only roots weeder has are the ones in your `weeder.toml` (by default `Main.main` and `Paths_*`).
  For a library package whose public API is exercised only by its own test suite, you'll want to declare the exposed modules as roots (e.g. with `root-modules`), otherwise excluding the test code makes the whole library look like a weed.

* `buildTests`: Whether to compile the test (and benchmark) code at all. Defaults to `includeTests`.

  The test artifacts land in a `hieTests` output of their own, so what is built and what weeder is shown are separate questions.
  Leave this alone unless something else in your repository needs the test code compiled with `-fwrite-ide-info` too.
  If it does, set `buildTests = true` and leave `includeTests = false`: weeder still sees only non-test code, and the other tool reads the same build instead of compiling everything a second time.

  ```nix
  weeder-check = weeder-nix.makeWeederCheck {
    weederToml = ./weeder.toml;
    packages = [ "foobar" "foobar-gen" ];
    # The other tool wants the test artifacts; weeder still must not see them.
    buildTests = true;
  };
  ```

See `./nix/weederCheckFor.nix` for the available arguments.

### `weederCheckFor`

Make a weeder check based on raw packages.
This assumes you've used something like `addHieOutput`.
You probably don't need to use this.

See `./nix/weederCheckFor.nix`.

### `addHieOutput`

Add `hie` and `hieTests` outputs to a Haskell package.
This adds `-fwrite-ide-info` and collects what the compiler wrote down about every module: the `.hie` file for what a module names, and the `.hi` interface for what it declares.

The two outputs are split by the kind of component the artifacts came from, read from the stanzas in the package's `.cabal` file: `hie` holds the library and the executables, `hieTests` holds the test suites and the benchmarks.
Each output holds one directory per component, because every component with a `main-is` declares a module called `Main`, and each tree is rooted where a module's own path starts, so `A.B.C` is at `A/B/C.hie`.

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
