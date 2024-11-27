{
  lib,
  config,
  ...
}:
let
  cfg = config.scale-network.users.jsh;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.users.jsh.enable = mkEnableOption "user jsh";

  config = mkIf cfg.enable {
    users.users = {
      jsh = {
        isNormalUser = true;
        uid = 2011;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfK7f1WvpQRhhB6UFeTOY5cB5uCzHFgP1DZZMwf75WZ"
        ];
      };
    };
  };
}
