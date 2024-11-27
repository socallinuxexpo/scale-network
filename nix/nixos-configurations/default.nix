inputs:
let
  inherit (builtins)
    readDir
    ;

  inherit (inputs.nixpkgs-unstable) lib;

  inherit (lib.attrsets)
    filterAttrs
    mapAttrs'
    nameValuePair
    ;

  inherit (lib.modules)
    mkDefault
    ;

  inherit (inputs.self.library)
    kebabToCamel
    ;
in
mapAttrs' (
  hostDirectory: _:
  nameValuePair (kebabToCamel hostDirectory) (
    let
      inherit (import ./${hostDirectory}) release modules;
    in
    inputs."nixpkgs-${release}".lib.nixosSystem {
      modules = [
        (
          { ... }:
          {
            networking.hostName = mkDefault hostDirectory;
            nixpkgs.overlays = [ inputs.self.overlays.default ];
          }
        )
        inputs.disko.nixosModules.disko
        inputs.self.nixosModules.default
        modules
      ];

      specialArgs = {
        inherit inputs;
      };
    }
  )
) (filterAttrs (_: fileType: fileType == "directory") (readDir ./.))
