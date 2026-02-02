{ lib, ... }:
let
  inherit (lib) mkEnableOption;
in
{
  options.scale = {
    passwordAuth = mkEnableOption "allow password auth via SSH";
  };
}
