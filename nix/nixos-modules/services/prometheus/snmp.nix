{ pkgs }:
let
  ifMIBs = builtins.fetchurl {
    url = "https://www.iana.org/assignments/ianaiftype-mib/ianaiftype-mib";
    name = "IANA-IFTYPE-MIB.txt";
  };
  juniperMIBs = builtins.fetchTarball {
    url = "https://www.juniper.net/documentation/software/junos/junos244/juniper-mibs-24.4R1.10.zip";

  };
in
pkgs.stdenv.mkDerivation {
  name = "snmp configuration";
  src = ./.;
  buildInputs = [
    ifMIBs
    juniperMIBs
  ];
  buildPhase = ''
    ${pkgs.prometheus-snmp-exporter}/bin/generator generate
  '';
}
