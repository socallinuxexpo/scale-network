{
  stdenvNoCC,
  lib,
  python3,
  python313Packages,
}:
let

  inherit (lib.fileset)
    toSource
    unions
    ;

  root = ../../../../..;

in
stdenvNoCC.mkDerivation {

  name = "scale-inventory";

  src = toSource {
    inherit root;
    fileset = unions [
      (root + "/switch-configuration")
      (root + "/facts")
    ];
  };

  propagatedBuildInputs = [
    python3
    python313Packages.jinja2
    python313Packages.pandas
  ];

  buildCommand = ''
    mkdir $out/{.repo,config} -p
    cp -r $src/* $out/.repo
    cd $out/.repo/facts
    python inventory.py all $out/config
  '';
}
