{ addHieOutput, weederCheckFor, haskellPackages }:
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
        value = addHieOutput super.${pname};
      })
      packages);

  newHaskellPackages = haskellPackages.extend addHieOutputOverride;
  cleanedArgs = builtins.removeAttrs args [ "haskellPackages" ];
  newPackages = builtins.map (pname: newHaskellPackages.${pname}) packages;
in
weederCheckFor (cleanedArgs // {
  packages = newPackages;
})
