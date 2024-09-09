let
  checkFor = pkgs: pkgs.callPackage ./checkFor.nix { };
in
{
  inherit checkFor;
  makeCheck = pkgs: pkgs.callPackage ./makeCheck.nix {
    addHieOutput = pkgs.callPackage ../haskell/addHieOutput.nix { };
    checkFor = checkFor pkgs;
  };
}
