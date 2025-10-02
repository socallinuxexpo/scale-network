{
  pkgs,
  lib,
}:
let
  inherit (pkgs.writers)
    writePython3Bin
    ;
  inherit (lib.strings)
    removePrefix
    ;

  scriptContent = builtins.readFile ./mac2eui64.py;
  scriptNoShebang = removePrefix "#!/usr/bin/env python3\n" scriptContent;
in
writePython3Bin "mac2eui64" {
  doCheck = true;
} scriptNoShebang
