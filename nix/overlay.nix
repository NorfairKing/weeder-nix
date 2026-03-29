final: _:
let
  addHieOutput = final.callPackage ./addHieOutput.nix { };
  buildTestsWithoutRunning = final.callPackage ./buildTestsWithoutRunning.nix { };
  disableOptimisation = final.callPackage ./disableOptimisation.nix { };
  weederCheckFor = final.callPackage ./weederCheckFor.nix {
    weeder = final.haskellPackages.weeder;
  };
  makeWeederCheck = final.callPackage ./makeWeederCheck.nix {
    inherit addHieOutput
      buildTestsWithoutRunning
      disableOptimisation
      weederCheckFor;
  };
in
{
  weeder-nix = {
    inherit
      addHieOutput
      buildTestsWithoutRunning
      disableOptimisation
      weederCheckFor
      makeWeederCheck;
  };
}
