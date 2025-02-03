{
  lib,
  python3,
  stdenvNoCC,
}:
let
  inherit (lib.fileset)
    toSource
    unions
    ;
in
stdenvNoCC.mkDerivation {

  name = "scaleInventory";

  src = toSource {
    root = ../../..;
    fileset = unions [
      ../../../facts
      ../../../switch-configuration
    ];
  };

  nativeBuildInputs = [
    (python3.withPackages (ps: [ ps.jinja2 ]))
  ];

  buildPhase = ''
    mkdir build
    cd facts
    python inventory.py all ../build
    cd ..
  '';

  installPhase = ''
    mkdir -p $out/config
    cp build/* $out/config/
  '';
}
