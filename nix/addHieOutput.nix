{ haskell }:
pkg:
# Add outputs holding what the compiler wrote down about every module: the
# .hie file for what a module names, and the .hi interface for what it
# declares.
#
# Two outputs rather than one, split by the kind of component the artifacts
# came from: 'hie' for the library and the executables, 'hieTests' for the
# test suites and the benchmarks. Weeder must not be given the test artifacts
# by default, because code that only a test uses is a weed, and a test suite
# in the graph makes well-tested dead code look alive. Splitting at build time
# rather than choosing at build time means one build answers for both: whoever
# reads it decides, and a repository with another tool that does want the test
# artifacts (a checker of test obligations, say) can share this build instead
# of compiling everything a second time.
#
# One directory per component, because every component with a main-is declares
# a module called Main and cabal writes each of them to Main.hie, so merging
# the trees would leave one file standing for all of them.
#
# Each tree is rooted where a module's own path starts, so that A.B.C is
# A/B/C.hie, because that is how a module is looked up. Cabal writes the .hie
# files under a per-component extra-compilation-artifacts directory, so
# keeping that prefix would leave every lookup missing; the interfaces are
# already rooted that way in the component's own build directory.
#
# The .hie files are moved, since nothing reads them where they were. The
# interfaces are copied, since the rest of the build is still using them.
# [ref:HieDirectory]
(haskell.lib.overrideCabal pkg
  (old: {
    configureFlags = (old.configureFlags or [ ]) ++ [
      "--ghc-options=-fwrite-ide-info"
    ];
    # [tag:HieDirectory]
    # Cabal will not be told to write these into the output directly, since a
    # configure flag is not expanded against the output variables, so they are
    # collected afterwards from wherever it put them.
    postBuild = (old.postBuild or "") + ''
      mkdir -p $hie $hieTests

      # Which components are test suites or benchmarks, from the stanzas that
      # declare them. Cabal names each component's build directory after its
      # stanza, and the stanza's keyword is the only place the kind of a
      # component is written down: an executable's build directory and a test
      # suite's are the same shape.
      weederNixTestComponents=" $(sed -nE \
        's/^(test-suite|benchmark)[[:space:]]+([A-Za-z0-9._-]+).*$/\2/p' \
        ./*.cabal | sort -u | tr '\n' ' ')"

      find . -type d -name hie -path '*extra-compilation-artifacts*' | sort | while read -r artifacts
      do
        # The path is dist/build/<component>/<component>-tmp/... for every
        # component with its own directory, and dist/build/... for the library.
        component=$(dirname "$artifacts" \
          | sed -e 's|^\./dist/build/\?||' -e 's|extra-compilation-artifacts$||' -e 's|/.*$||')

        case "$weederNixTestComponents" in
          *" $component "*) root=$hieTests ;;
          *) root=$hie ;;
        esac
        target=$root/''${component:-lib}
        mkdir -p "$target"

        ( cd "$artifacts"
          find . -name '*.hie' | while read -r found
          do
            mkdir -p "$target/$(dirname "$found")"
            mv "$found" "$target/$found"
          done
        )
        # The library's build directory holds every other component's
        # directory too, so its own interfaces are the ones not under a
        # component's -tmp.
        ( cd "$(dirname "$(dirname "$artifacts")")"
          find . -name '*.hi' -not -path '*-tmp/*' | while read -r found
          do
            mkdir -p "$target/$(dirname "$found")"
            cp "$found" "$target/$found"
          done
        )
      done
    '';
  })).overrideAttrs (old: {
  outputs = (old.outputs or [ ]) ++ [ "hie" "hieTests" ];
})
