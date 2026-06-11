{ addHieOutput, buildTestsWithoutRunning, disableOptimisation, weederCheckFor, haskellPackages }:
let
  # Funky variable scoping trick to give haskellPackages a default value below.
  x = haskellPackages;
in
args@{ packages
, haskellPackages ? x
, # Whether to feed weeder the .hie files of test (and benchmark) code.
  #
  # When false (the default), weeder only sees non-test code, so anything
  # that is used _only_ by tests is reported as a weed.
  #
  # When true, the test suite's .hie files are included as well, so anything
  # the tests use counts as used. This prevents false-positives for code
  # that exists only to be tested, at the cost of not catching test-only
  # code.
  includeTests ? false
, ...
}:
let
  maybeBuildTests = if includeTests then buildTestsWithoutRunning else (pkg: pkg);
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
  cleanedArgs = builtins.removeAttrs args [ "haskellPackages" "includeTests" ];
  newPackages = builtins.map (pname: newHaskellPackages.${pname}) packages;
in
weederCheckFor (cleanedArgs // {
  packages = newPackages;
})
