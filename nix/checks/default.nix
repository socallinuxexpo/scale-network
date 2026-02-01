inputs:
let

  inherit (inputs.nixpkgs-lib)
    lib
    ;

  inherit (lib.attrsets)
    mapAttrs
    ;

in
mapAttrs (system: pkgs: {

  formatting = inputs.self.formatterModule.${system}.config.build.check inputs.self;

}) inputs.self.legacyPackages
