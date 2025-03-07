{
  lib,
  config,
  ...
}:
let
  cfg = config.scale-network.users.samuel;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.users.kylerisse.enable = mkEnableOption "user samuel";

  config = mkIf cfg.enable {
    users.users = {
      samuel = {
        isNormalUser = true;
        uid = 2014;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIdOz5xsqRF/iP2NsdnPrr1NC9qxMIWEGVhMyW6yzQKr samuel@robin"
        ];
      };
    };
  };
}
