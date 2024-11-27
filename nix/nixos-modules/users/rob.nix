{
  lib,
  config,
  ...
}:
let
  cfg = config.scale-network.users.rob;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.users.rob.enable = mkEnableOption "user rob";

  config = mkIf cfg.enable {
    users.users = {
      rob = {
        isNormalUser = true;
        uid = 2005;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEiESod7DOT2cmT2QEYjBIrzYqTDnJLld1em3doDROq"
        ];
      };
    };
  };
}
