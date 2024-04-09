{ addHieOutput, weederCheckScriptFor }:
args@{ packages, haskellPackages, ... }:
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
weederCheckScriptFor (cleanedArgs // {
  packages = newPackages;
})
