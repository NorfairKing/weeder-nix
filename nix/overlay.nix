final: _:
let
  addHieOutput = final.callPackage ./addHieOutput.nix { };
  weederCheckFor = final.callPackage ./weederCheckFor.nix {
    weeder = final.haskellPackages.weeder;
  };
  makeWeederCheck = final.callPackage ./makeWeederCheck.nix {
    inherit addHieOutput
      weederCheckFor;
  };
in
{
  weeder-nix = {
    inherit
      addHieOutput
      weederCheckFor
      makeWeederCheck;
  };
}
