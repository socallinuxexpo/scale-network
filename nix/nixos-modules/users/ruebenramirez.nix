{
  lib,
  config,
  ...
}:
let
  cfg = config.scale-network.users.ruebenramirez;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.users.ruebenramirez.enable = mkEnableOption "user ruebenramirez";

  config = mkIf cfg.enable {
    users.users = {
      ruebenramirez = {
        isNormalUser = true;
        uid = 2009;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAkQS5ohCDizq24WfDgP/dEOonD/0WfrI0EAZFCyS0Ea"
        ];
      };
    };
  };
}
