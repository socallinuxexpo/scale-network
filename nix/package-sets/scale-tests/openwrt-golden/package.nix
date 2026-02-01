{
  diffutils,
  gomplate,
  lib,
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
  pname = "openwrt-golden";
  version = "0.1.0";

  src = toSource {
    inherit root;
    fileset = unions [
      (root + "/facts")
      (root + "/openwrt")
      (root + "/tests")
    ];
  };

  buildInputs = [
    diffutils
    gomplate
  ];

  buildPhase = ''
    cd tests/unit/openwrt
    mkdir -p $out/tmp/ath79
  '';

  installPhase = ''
    ./test.sh -t ath79 -o $out
  '';
})
