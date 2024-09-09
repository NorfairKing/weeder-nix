{ addHieOutput, checkFor }:
pkgs:
args@{ packages
, haskellPackages ? pkgs.haskellPackages
, ...
}:
let
  addHieOutputOverride = _: super:
    builtins.listToAttrs (builtins.map
      (pname: {
        name = pname;
        value = addHieOutput pkgs super.${pname};
      })
      packages);

  newHaskellPackages = haskellPackages.extend addHieOutputOverride;
  newPackages = builtins.map (pname: newHaskellPackages.${pname}) packages;
in
checkFor pkgs ({ inherit haskellPackages; } // args // {
  packages = newPackages;
})
