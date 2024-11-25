{
  stdenvNoCC,
  copyPathsToStore,
  lib,
  expect,
  openssh,
  bash,
}:
let
  local_manifests = copyPathsToStore [
    ../../../openwrt/scripts/massflash/massflash
  ];
in
stdenvNoCC.mkDerivation {
  name = "massflash";

  propagatedBuildInputs = [
    bash
    openssh
  ];

  buildCommand = ''
    mkdir -p $out/bin
    for local_manifest in ${lib.concatMapStringsSep " " toString local_manifests}; do
      cp -r $local_manifest $out/bin/$(stripHash $local_manifest; echo $strippedName)
    done
  '';
}
