{ lib, addHieOutput, buildTestsWithoutRunning, disableOptimisation, weederCheckFor, haskellPackages }:
let
  # Funky variable scoping trick to give haskellPackages a default value below.
  x = haskellPackages;
in
args@{ packages
, haskellPackages ? x
, # Whether to feed weeder the .hie files of test (and benchmark) code.
  #
  # When false (the default), weeder only sees non-test code, so anything
  # that is used _only_ by tests is reported as a weed. That is the point:
  # with the test suite in the graph, dead code that happens to be
  # well-tested looks alive.
  #
  # When true, the test suite's .hie files are included as well, so anything
  # the tests use counts as used. This prevents false-positives for code
  # that exists only to be tested, at the cost of not catching test-only
  # code.
  includeTests ? false
, # Whether to compile the test (and benchmark) code at all.
  #
  # Defaults to whether weeder is going to read it, which is the cheapest
  # thing for a repository whose only use of this build is weeder.
  #
  # Set it on with `includeTests` off when something else in the same
  # repository needs the test code compiled with ide info: the artifacts land
  # in the `hieTests` output either way, weeder is not shown them, and the
  # other tool reads the same build instead of compiling everything again.
  buildTests ? includeTests
, ...
}:
assert
lib.assertMsg (buildTests || !includeTests)
  "weeder-nix: includeTests is set but buildTests is not, so there would be no test artifacts to include.";
let
  maybeBuildTests = if buildTests then buildTestsWithoutRunning else (pkg: pkg);
  addHieOutputOverride = _: super:
    builtins.listToAttrs (builtins.map
      (pname: {
        name = pname;
        # We disable optimisation because weeder only needs .hie files,
        # not optimised code.
        value = disableOptimisation (maybeBuildTests (addHieOutput super.${pname}));
      })
      packages);

  newHaskellPackages = haskellPackages.extend addHieOutputOverride;
  cleanedArgs = builtins.removeAttrs args [ "haskellPackages" "buildTests" ];
  newPackages = builtins.map (pname: newHaskellPackages.${pname}) packages;
in
weederCheckFor (cleanedArgs // {
  packages = newPackages;
})
