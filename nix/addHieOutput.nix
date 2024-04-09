{ haskell
, rsync
}:
pkg:
# [tag:DisableTests]
# In order to prevent false-positives, weeder must get access to the
# .hie files of the test suite as well.
# Cabal doesn't build testing code unless tests are turned on, but we
# don't actually want to run tests for this build, so we enable tests
# with 'doCheck', but then don't run them, by setting checkPhase to
# an empty string.

haskell.lib.overrideCabal
  (pkg.overrideAttrs (old: {
    outputs = (old.outputs or [ ]) ++ [ "hie" ];
    # Turn off running of tests.
    # [ref:DisableTests]
    checkPhase = "";
    # [tag:HieDirectory]
    # We'd prefer to redirect cabal to outputting the hie output
    # directly into $hie but I could not figure out how to do that
    # because passing '--ghc-options=-hiedir=$out' as a configure
    # flag doesn't seem to expand the $out variable.
    # TODO: I'd really like to do this without rsync if we can, ideally with a
    # way to make -hiedir=$out work, but even if not, so we don't have to
    # depend on a specific nixpkgs.
    postBuild = (old.postBuild or "") + ''
      mkdir -p $hie
      ${rsync}/bin/rsync -am \
        --include='*/' \
        --include='*.hie' \
        --exclude='*' \
        . $hie
    '';
  }))
  (old: {
    # Turn on building of tests.
    # [ref:DisableTests]
    doCheck = true;
    doBenchmark = true;
    # Enable outputting hie info.
    # [ref:HieDirectory]
    configureFlags = (old.configureFlags or [ ]) ++ [
      "--ghc-options=-fwrite-ide-info"
    ];
  })
