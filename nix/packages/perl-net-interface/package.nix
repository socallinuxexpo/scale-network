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

  CPPFLAGS="-Iusr/include";

  postPatch = ''
    mkdir -p usr/include/sys/
    cp -pr ${linuxHeaders}/include usr/
    ln -s ${linuxHeaders}/include/linux/socket.h usr/include/sys/socket.h
    ls -lahR usr/
    echo "aaaaaaaa"
    echo $CPPFLAGS
  '';

  src = fetchurl {
    url = "mirror://cpan/authors/id/M/MI/MIKER/Net-Interface-1.016.tar.gz";
    hash = "sha256-e+RGk14BPQ7dPTcfkvuQo7s4q+mVYoidgXiVMSnlNQg=";
  };
}
