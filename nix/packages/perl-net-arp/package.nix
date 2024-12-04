{
  perlPackages,
  fetchurl,
}:

perlPackages.buildPerlPackage {
  pname = "NetArp";
  version = "1.0.12";
  src = fetchurl {
    url = "mirror://cpan/authors/id/C/CR/CRAZYDJ/Net-ARP-1.0.12.tar.gz";
    hash = "sha256-KK2GBaOh4PhoqYmIJvVGHYCSPm66GtXgRzfmDoug7HA=";
  };
}
