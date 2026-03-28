{ haskell
, rsync
}:
pkg:
# Add a 'hie' output to a haskell package that contains all the .hie files
# produced during compilation.

(haskell.lib.overrideCabal pkg
  (old: {
    # Enable outputting hie info.
    # [ref:HieDirectory]
    configureFlags = (old.configureFlags or [ ]) ++ [
      "--ghc-options=-fwrite-ide-info"
    ];
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
  })).overrideAttrs (old: {
  outputs = (old.outputs or [ ]) ++ [ "hie" ];
})
