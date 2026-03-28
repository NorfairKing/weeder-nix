{ haskell }:
pkg:
# Build test code without running it.
#
# Cabal doesn't build testing code unless tests are turned on, but
# sometimes you want the compiled test code (e.g. for .hie files)
# without actually running the test suite.
#
# This enables doCheck (so test code is compiled and test dependencies
# are available) but sets checkPhase to "" so the test suite is not
# executed.
haskell.lib.overrideCabal pkg
  (_: {
    doCheck = true;
    doBenchmark = true;
    checkPhase = "";
  })
