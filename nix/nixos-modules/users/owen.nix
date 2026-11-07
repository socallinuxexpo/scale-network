{
  lib,
  config,
  ...
}:
let
  cfg = config.scale-network.users.owen;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.users.owen.enable = mkEnableOption "user owen";

  config = mkIf cfg.enable {
    users.users = {
      owen = {
        isNormalUser = true;
        uid = 2006;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINT9FKHdDbHRQ2JiuNl2fzJFOZcHrB3fLwEAQN/8B+wQ owen@kiev-544.local"
        ];
      };
    };
  };
}
