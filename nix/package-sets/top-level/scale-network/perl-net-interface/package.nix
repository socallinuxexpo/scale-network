{
  perlPackages,
  fetchurl,
}:
perlPackages.buildPerlPackage {
  pname = "NetInterface";
  version = "1.016";

  src = fetchurl {
    url = "mirror://cpan/authors/id/M/MI/MIKER/Net-Interface-1.016.tar.gz";
    hash = "sha256-e+RGk14BPQ7dPTcfkvuQo7s4q+mVYoidgXiVMSnlNQg=";
  };

  env.NIX_CFLAGS_COMPILE = toString [ "-Wno-error=incompatible-pointer-types" ];

  patches = [ ./net-interface-remove-grep-af-inet.patch ];

  doCheck = false;
}
