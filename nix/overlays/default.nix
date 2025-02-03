inputs:
let
  inherit (builtins)
    attrValues
    ;

  inherit (inputs.nixpkgs-unstable)
    lib
    ;

  inherit (lib.attrsets)
    genAttrs
    ;

  inherit (lib.fixedPoints)
    composeManyExtensions
    ;

  inherit (inputs.self.library)
    attrNamesKebabToCamel
    kebabToCamel
    getDirectories
    ;

  allLocalPackages = attrNamesKebabToCamel (
    genAttrs (getDirectories ../packages) (
      dir: final: prev: {
        scale-network = prev.scale-network or { } // {
          "${kebabToCamel dir}" = final.callPackage ../packages/${dir}/package.nix { };
        };
      }
    )
  );

  default = composeManyExtensions (attrValues allLocalPackages);
in
allLocalPackages // { inherit default; }
