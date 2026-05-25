inputs:
let

  inherit (inputs.nixpkgs-lib)
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
    isc-dhcp
    mac2eui64
    make-dhcpd
    massflash
    massflash-generate-persist
    scale-inventory
    serverspec
    perl-net-arp
    perl-net-interface
    perl-net-ping
    rperf
    ;
})) inputs.self.legacyPackages
