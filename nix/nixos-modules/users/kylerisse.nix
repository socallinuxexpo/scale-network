{
  lib,
  config,
  ...
}:
let
  cfg = config.scale-network.users.kylerisse;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.users.kylerisse.enable = mkEnableOption "user kylerisse";

  config = mkIf cfg.enable {
    users.users = {
      kylerisse = {
        isNormalUser = true;
        uid = 2007;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPcTYYr/TGH4vRCaY4WU4Qc7RlzzBOHv2XYxGwCzV+fg"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKX8NM1OQECwhNTQE0qAm422uq9L0i0Y/hvPPc4tHIOX"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwETBVGk/A/3TZgmB/lVy7KZdY62ywNODx3HJk698PP"
        ];
      };
    };
  };
}
