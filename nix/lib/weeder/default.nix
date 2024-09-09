let
  addHieOutput = import ../haskell/addHieOutput.nix;
  checkFor = import ./checkFor.nix;
in
{
  inherit checkFor;
  makeCheck = import ./makeCheck.nix { inherit addHieOutput checkFor; };
}
