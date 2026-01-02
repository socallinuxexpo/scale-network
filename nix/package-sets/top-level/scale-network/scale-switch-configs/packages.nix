{ stdenvNoCC
, perl
, gcc
, lib
, breakpointHook
}:

stdenvNoCC.mkDerivation {

  name = "scale-switch-configs";

  buildInputs = [ perl gcc ];
  nativeBuildInputs = [ breakpointHook ];
  src = lib.fileset.toSource {
    root = ./../..;
    fileset = lib.fileset.unions [
      ../../switch-configuration
      ../../Makefile
      ../../facts
    ];
  };
    #cd switch-configuration
    #make switch-maps-bundle
    buildCommand = ''
    make show
  '';
}
