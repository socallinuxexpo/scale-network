inputs:
let
  inherit (builtins)
    attrNames
    attrValues
    readDir
    ;

  inherit (inputs.nixpkgs-unstable)
    lib
    ;

  inherit (lib.attrsets)
    filterAttrs
    genAttrs
    mapAttrs'
    ;

  inherit (lib.fixedPoints)
    composeManyExtensions
    ;

  inherit (lib.lists)
    remove
    ;

  inherit (inputs.self.library)
    attrNamesKebabToCamel
    kebabToCamel
    ;

  getDirectories =
    path: attrNames (filterAttrs (_: fileType: fileType == "directory") (readDir path));

  allLocalPackages = attrNamesKebabToCamel (
    genAttrs (getDirectories ../packages) (
      dir: final: prev: {
        scale-network = prev.scale-network or { } // {
          "${kebabToCamel dir}" = final.callPackage ../packages/${dir}/package.nix { };
        };
        frr = prev.frr.overrideAttrs (old: {
          configureFlags = remove "--localstatedir=/run/frr" old.configureFlags ++ [ "--localstatedir=/var" ];
        });
      }
    )
  );

  default = composeManyExtensions (attrValues allLocalPackages);
in
allLocalPackages // { inherit default; }
