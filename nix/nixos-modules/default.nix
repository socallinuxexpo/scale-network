inputs:
let

  inherit (inputs.nixpkgs)
    lib
    ;

  inherit (lib.filesystem)
    listFilesRecursive
    ;

  inherit (lib.lists)
    filter
    ;

  inherit (lib.strings)
    hasSuffix
    ;

in
{
  default =
    { ... }:
    {
      imports = filter (hasSuffix ".nix") (filter (path: path != ./default.nix) (listFilesRecursive ./.));
    };
}
