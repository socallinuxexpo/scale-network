inputs:
let

  # inherits

  inherit (builtins)
    attrValues
    ;

  inherit (inputs.nixpkgs-unstable)
    lib
    ;

  inherit (lib.attrsets)
    genAttrs
    ;

  inherit (lib.filesystem)
    packagesFromDirectoryRecursive
    ;

  inherit (lib.fixedPoints)
    composeManyExtensions
    ;

  inherit (inputs.self)
    library
    ;

  inherit (library.path)
    getDirectoryNames
    joinParentToPaths
    ;

  # overlays

  toplevelOverlays =
    final: prev:
    packagesFromDirectoryRecursive {
      inherit (final) callPackage;
      inherit (prev) newScope;
      directory = ../package-sets/top-level;
    };

  packageOverrides =
    (
      parent:
      (genAttrs (getDirectoryNames parent) (
        dir:
        import (
          joinParentToPaths parent [
            dir
            "overlay.nix"
          ]
        )
      ))
    )
      ./package-overrides;

  default = composeManyExtensions ((attrValues packageOverrides) ++ [ toplevelOverlays ]);
in
packageOverrides // { inherit default; }
