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
  core = pkgs.testers.runNixOSTest (import ./core.nix { inherit inputs lib; });
  routers = pkgs.testers.runNixOSTest (import ./routers.nix { inherit inputs; });
  router-border = pkgs.testers.runNixOSTest (import ./router-border.nix { inherit inputs lib; });
  loghost = pkgs.testers.runNixOSTest (import ./loghost.nix { inherit inputs; });
  monitor = pkgs.testers.runNixOSTest (import ./monitor.nix { inherit inputs; });
  wasgeht = pkgs.testers.runNixOSTest (import ./wasgeht.nix { inherit inputs; });

  formatting = inputs.self.formatterModule.${system}.config.build.check inputs.self;

}) inputs.self.legacyPackages
