{ stdenvNoCC
, copyPathsToStore
, lib
, python3
, python310Packages
}:
let
  local_manifests = copyPathsToStore [
    ../../switch-configuration
    ../../ansible
    ../../facts
  ];
in
stdenvNoCC.mkDerivation {

  name = "scaleInventory";

  propagatedBuildInputs = [ python3 python310Packages.jinja2 ];

  buildCommand = ''
    mkdir $out
    cd $out
    mkdir .repo
    mkdir config
    for local_manifest in ${lib.concatMapStringsSep " " toString local_manifests}; do
      cp -r $local_manifest .repo/$(stripHash $local_manifest; echo $strippedName)
    done
    cd $out/.repo/facts
    python inventory.py all $out/config
  '';
}
