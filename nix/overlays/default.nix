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

    scale-nixos-tests =
      let
        root = ../package-sets/scale-nixos-tests;
      in
      {

        core = final.testers.runNixOSTest (import (root + "/core.nix") { inherit inputs lib; });

        loghost = final.testers.runNixOSTest (import (root + "/loghost.nix") { inherit inputs; });

        monitor = final.testers.runNixOSTest (import (root + "/monitor.nix") { inherit inputs; });

        routers = final.testers.runNixOSTest (import (root + "/routers.nix") { inherit inputs; });

        router-border = final.testers.runNixOSTest (
          import (root + "/router-border.nix") { inherit inputs lib; }
        );

        wasgeht = final.testers.runNixOSTest (import (root + "/wasgeht.nix") { inherit inputs; });

      };
  };

in
packageOverrides // { inherit default scale-tests; }
