{ haskell }:
pkg:
# Disable optimisation and interface pragmas.
# Weeder only needs .hie files, so there is no point spending time on
# optimisation or writing unfoldings to .hi files.
haskell.lib.appendConfigureFlags pkg [
  "--ghc-options=-O0"
  "--ghc-options=-fignore-interface-pragmas"
  "--ghc-options=-fomit-interface-pragmas"
]
