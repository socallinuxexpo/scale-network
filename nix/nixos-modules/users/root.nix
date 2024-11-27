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
    users.extraUsers.root.hashedPassword = "$6$3Hm/K5fbR3UEMK6H$3aaegtdwvejGk9Bk0ttN5bNJn4z2Yt6LWXD3nGI7.44Pbm7A1TpKuxG9XQLwsj7M9NEk8eB5Exg0qVRV//6br/";
  };
}
