{
  perlPackages,
}:

perlPackages.NetPing.overrideAttrs {
  # Owen's patch for _isroot should consider CAP_NET_RAW capability on Linux
  # related to: https://rt.cpan.org/Public/Bug/Display.html?id=139820
  patches = [ ./linux-isroot-capability.patch ];
}
