{
  perlPackages,
  fetchurl,
  linuxHeaders,
  which
}:

perlPackages.buildPerlPackage {
  pname = "NetInterface";
  version = "1.016";
  buildInputs = [ linuxHeaders which ];
  doCheck = false;
  src = fetchurl {
    url = "mirror://cpan/authors/id/M/MI/MIKER/Net-Interface-1.016.tar.gz";
    hash = "sha256-e+RGk14BPQ7dPTcfkvuQo7s4q+mVYoidgXiVMSnlNQg=";
  };
}
