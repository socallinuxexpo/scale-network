inputs:
let

  inherit (inputs.nixpkgs)
    lib
    ;

  inherit (lib.attrsets)
    mapAttrs
    ;

  inherit (lib.trivial)
    const
    ;

in
mapAttrs (const (module: module.config.build.wrapper)) inputs.self.formatterModule
