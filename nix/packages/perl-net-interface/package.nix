{
  perlPackages,
  fetchurl,
  linuxHeaders,
}:

perlPackages.buildPerlPackage {
  pname = "NetInterface";
  version = "1.015";
  buildInputs = [ linuxHeaders ];
  doCheck = false;
  src = fetchurl {
    url = "mirror://cpan/authors/id/M/MI/MIKER/Net-Interface-1.015.tar.gz";
    hash = "sha256-x6MFjTGh73k+eAtqTJCQEI/SxMNFeQ774AeFKgIvf4E=";
  };
}
