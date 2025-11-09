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
    make-dhcpd
    massflash
    scale-inventory
    serverspec
    perl-net-arp
    perl-net-interface
    perl-net-ping
    ;
})) inputs.self.legacyPackages
