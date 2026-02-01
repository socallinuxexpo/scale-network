inputs:
let
  # inherits
  inherit (inputs.nixpkgs-lib)
    lib
    ;

  inherit (lib.attrsets)
    mapAttrs
    ;

  inherit (lib.fileset)
    toSource
    unions
    ;

  # sources

  # Used for derivations where openwrt is the primary directory.
  openwrtSrc = toSource {
    root = ../..;
    fileset = unions [
      ../../facts
      ../../openwrt
      ../../tests
    ];
  };
in
mapAttrs (system: pkgs: {
  core = pkgs.testers.runNixOSTest (import ./core.nix { inherit inputs lib; });
  routers = pkgs.testers.runNixOSTest (import ./routers.nix { inherit inputs; });
  router-border = pkgs.testers.runNixOSTest (import ./router-border.nix { inherit inputs lib; });
  loghost = pkgs.testers.runNixOSTest (import ./loghost.nix { inherit inputs; });
  monitor = pkgs.testers.runNixOSTest (import ./monitor.nix { inherit inputs; });
  wasgeht = pkgs.testers.runNixOSTest (import ./wasgeht.nix { inherit inputs; });

  openwrt-golden = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "openwrt-golden";
    version = "0.1.0";

    src = openwrtSrc;

    buildInputs = [
      pkgs.diffutils
      pkgs.gomplate
    ];

    buildPhase = ''
      cd tests/unit/openwrt
      mkdir -p $out/tmp/ath79
    '';

    installPhase = ''
      ./test.sh -t ath79 -o $out
    '';
  });

  formatting = inputs.self.formatterModule.${system}.config.build.check inputs.self;

}) inputs.self.legacyPackages
