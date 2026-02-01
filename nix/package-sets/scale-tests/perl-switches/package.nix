{
  gnumake,
  lib,
  perl,
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
