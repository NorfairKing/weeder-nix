# This file is exposed as part of the public API.
final: _:
let
  weeder = import ./lib/weeder.nix;
in
{
  weeder-nix =
    builtins.mapAttrs (_k: v: v final) (import ./lib/haskell.nix)
    // {
      weederCheckFor = weeder.checkFor final;
      makeWeederCheck = weeder.makeCheck final;
    };
}
