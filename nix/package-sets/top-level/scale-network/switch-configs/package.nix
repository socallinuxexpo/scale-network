{
  stdenvNoCC,
  perl,
  gnumake,
  lib,
  ghostscript_headless,
}:
let
  inherit (lib.fileset)
    toSource
    unions
    ;

  root = ../../../../..;
in
stdenvNoCC.mkDerivation {

  name = "switch-configs";

  src = toSource {
    inherit root;
    fileset = unions [
      (root + "/facts")
      (root + "/switch-configuration")
    ];
  };

  nativeBuildInputs = [
    perl
    gnumake
    ghostscript_headless
  ];

  buildCommand = ''
    mkdir -p $out/{.repo,config}
    cp --no-preserve=all -r $src/* $out/.repo
    cd $out/.repo/switch-configuration
    make all
    mkdir -p $out
    ln -s $out/.repo/switch-configuration/config/switch-maps $out/switch-maps
    ln -s $out/.repo/switch-configuration/config/output $out/output
  '';
}
