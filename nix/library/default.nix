inputs:
let
  inherit (inputs.nixpkgs-unstable) lib;

  inherit (lib.strings)
    splitString
    substring
    toLower
    toUpper
    concatMapStrings
    ;
in
rec {

  mutFirstChar =
    f: s:
    let
      firstChar = f (substring 0 1 s);
      rest = substring 1 (-1) s;
    in
    firstChar + rest;

  kebabToCamel =
    s: mutFirstChar toLower (concatMapStrings (mutFirstChar toUpper) (splitString "-" s));

}
