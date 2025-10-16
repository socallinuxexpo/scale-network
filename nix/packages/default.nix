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
mapAttrs (const (pkgs: {
  inherit (pkgs.scale-network)
    dhcptest
    mac2eui64
    makeDhcpd
    massflash
    scaleInventory
    serverspec
    perlNetArp
    perlNetInterface
    perlNetPing
    ;
})) inputs.self.legacyPackages
