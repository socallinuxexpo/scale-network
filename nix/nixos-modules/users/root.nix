{
  lib,
  config,
  ...
}:
let
  cfg = config.scale-network.users.root;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.users.root.enable = mkEnableOption "user root and sudo configs";

  config = mkIf cfg.enable {
    security.sudo = {
      extraConfig = ''
        Defaults rootpw
        Defaults lecture="never"
      '';
    };

    users.mutableUsers = false;
    users.extraUsers.root.hashedPassword = "$6$fdmMoUSxXGhjJYKK$iy8CUzXICDhssjiQN53/juZfxqGg/KbKf60M.tho2HUcFWnvmnhAEx55SwQWzTiI2rfnLA9Xlbz.vweS/8LD9.";
  };
}
