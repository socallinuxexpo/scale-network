{
  gnumake,
  lib,
  perl,
  perlPackages,
  scale-network,
  stdenv,
}:
let

  inherit (lib.fileset)
    toSource
    unions
    ;

  root = ../../../..;

in
stdenv.mkDerivation (finalAttrs: {
  pname = "perl-switches";
  version = "0.1.0";

  src = toSource {
    inherit root;
    fileset = unions [
      (root + "/facts")
      (root + "/switch-configuration")
    ];
  };

  nativeBuildInputs = [
    gnumake
    perl
    perlPackages.Expect
    perlPackages.TermReadKey
    perlPackages.NetSFTPForeign
    scale-network.perl-net-arp
    scale-network.perl-net-interface
    scale-network.perl-net-ping
  ];

  buildPhase = ''
    cd switch-configuration
    make .lint
    make .build-switch-configs
  '';

  installPhase = ''
    touch $out
  '';
})
