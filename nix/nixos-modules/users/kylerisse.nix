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
        openssh.authorizedKeys.keyFiles = [ (../../../facts/keys/kylerisse_id_ed25519.pub) ];
      };
    };
  };
}
