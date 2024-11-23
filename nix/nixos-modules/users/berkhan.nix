{
  lib,
  config,
}:
let
  cfg = config.scale-network.users.berkhan;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.users.berkhan.enable = mkEnableOption "user berkhan";

  config = mkIf cfg.enable {
    users.users = {
      berkhan = {
        isNormalUser = true;
        uid = 2100;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH6UhZ/oPqiFzCOxoZWeUqeGZCVLLNQbHH3uuIa6PCTz"
        ];
      };
    };
  };
}
