inputs:
let

  inherit (inputs.nixpkgs-lib)
    lib
    ;

  inherit (lib.attrsets)
    genAttrs
    ;

  inherit (lib.modules)
    mkDefault
    ;

  inherit (inputs.self.library.path)
    getDirectoryNames
    ;

in
genAttrs (getDirectoryNames ./.) (
  host:
  (
    let
      inherit (import ./${host}) release modules;
    in
    inputs."nixpkgs-${release}".lib.nixosSystem {
      modules = [
        (
          { ... }:
          {
            networking.hostName = mkDefault host;
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
)
