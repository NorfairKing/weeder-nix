final: _:
let
  addHieOutput = final.callPackage ./addHieOutput.nix { };
  buildTestsWithoutRunning = final.callPackage ./buildTestsWithoutRunning.nix { };
  weederCheckFor = final.callPackage ./weederCheckFor.nix {
    weeder = final.haskellPackages.weeder;
  };
  makeWeederCheck = final.callPackage ./makeWeederCheck.nix {
    inherit addHieOutput
      buildTestsWithoutRunning
      weederCheckFor;
  };
in
{
  weeder-nix = {
    inherit
      addHieOutput
      buildTestsWithoutRunning
      weederCheckFor
      makeWeederCheck;
  };
}
