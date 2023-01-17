{ stdenvNoCC
, copyPathsToStore
, lib
, python310
, jq
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

  propagatedBuildInputs = [ python310 jq ];

  buildCommand = ''
    mkdir $out
    cd $out
    mkdir .repo
    mkdir config
    for local_manifest in ${lib.concatMapStringsSep " " toString local_manifests}; do
      cp -r $local_manifest .repo/$(stripHash $local_manifest; echo $strippedName)
    done
    cd $out/.repo/facts
    python inventory.py | jq . > $out/config/kea.json
  '';
}
