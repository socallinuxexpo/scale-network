{
  lib,
  config,
  ...
}:
let
  cfg = config.scale-network.users.conjones;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.users.conjones.enable = mkEnableOption "user conjones";

  config = mkIf cfg.enable {
    users.users = {
      conjones = {
        isNormalUser = true;
        uid = 2012;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA0JyiGQCbLtjVoi72VA0pR4GjvKqL2JeiqbsxLndZvn"
        ];
      };
    };
  };
}
