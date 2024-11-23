{
  lib,
  config,
}:
let
  cfg = config.scale-network.users.dlang;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.users.dlang.enable = mkEnableOption "user dlang";

  config = mkIf cfg.enable {
    users.users = {
      dlang = {
        isNormalUser = true;
        uid = 2008;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEqPnzsYPKyURdnUpZx1nt9RFQjaz9q7m5wh525Crsho"
        ];
      };
    };
  };
}
