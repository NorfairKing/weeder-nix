{ addHieOutput, buildTestsWithoutRunning, disableOptimisation, weederCheckFor, haskellPackages }:
let
  # Funky variable scoping trick to give haskellPackages a default value below.
  x = haskellPackages;
in
args@{ packages
, haskellPackages ? x
, ...
}:
let
  addHieOutputOverride = _: super:
    builtins.listToAttrs (builtins.map
      (pname: {
        name = pname;
        # In order to prevent false-positives, weeder must get access to
        # the .hie files of the test suite as well.
        # We disable optimisation because weeder only needs .hie files,
        # not optimised code.
        value = disableOptimisation (buildTestsWithoutRunning (addHieOutput super.${pname}));
      })
      packages);

  newHaskellPackages = haskellPackages.extend addHieOutputOverride;
  cleanedArgs = builtins.removeAttrs args [ "haskellPackages" ];
  newPackages = builtins.map (pname: newHaskellPackages.${pname}) packages;
in
weederCheckFor (cleanedArgs // {
  packages = newPackages;
})
