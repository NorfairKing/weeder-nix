pkgs:
{
  # Name of the check derivation
  name ? "weeder-check"
, # Path to the weeder config file.
  # This is technically optional but you'll probably want to use on of your
  # own.
  weederToml ? null
, # List of packages to make the check for
  # These must have a `.hie` output.
  # You can give them that with the `addHieOutput` function but the
  # `makeWeederCheck` function does that for you.
  packages ? [ ]
, # Only make a report of the weeds, don't fail if there are any weeds.
  reportOnly ? false
, # Extra arguments for the weeder invocation
  extraArgs ? ""
, haskellPackages ? pkgs.haskellPackages
}:
let
  packageHieDirArg = pkg: "--hie-directory ${pkg.hie}";
  packageHieDirArgs = builtins.map packageHieDirArg packages;
  args = pkgs.lib.concatStringsSep " " packageHieDirArgs;
  configArg =
    if builtins.isNull weederToml
    then "--write-default-config"
    else "--config ${weederToml}";
  outArg = pkgs.lib.optionalString reportOnly "> $out 2>&1";
in
pkgs.runCommand name { } ''
  export LC_ALL=C.UTF-8 # Locale issue with rendering the config file
  ${pkgs.lib.optionalString reportOnly "set +e"}
  ${haskellPackages.weeder}/bin/weeder ${configArg} ${args} ${extraArgs} ${outArg}
  touch $out # Make sure that the result is definitely created, even if there are no weeds.
''
