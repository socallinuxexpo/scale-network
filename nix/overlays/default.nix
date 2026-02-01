inputs:
let

  # inherits

  inherit (builtins)
    attrValues
    ;

  inherit (inputs.nixpkgs-lib)
    lib
    ;

  inherit (lib.attrsets)
    genAttrs
    ;

  inherit (lib.customisation)
    makeScope
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

  scale-tests = final: prev: {
    scale-tests = makeScope prev.newScope (
      (
        parent: self:
        genAttrs (getDirectoryNames parent) (name: self.callPackage (parent + "/${name}/package.nix") { })
      )
        ../package-sets/scale-tests
    );
  };

in
packageOverrides // { inherit default scale-tests; }
