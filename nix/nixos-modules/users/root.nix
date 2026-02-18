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
    users.extraUsers.root.hashedPassword = "$6$overengineering$WLosSZa9..U4dwugMfLl0g0LrPkG67UlF5S3zng7pLEiyKTDGFJGzLp.VUmYpidNS.kwBtG3AY/f.DRk7Ri9b0";
  };
}
