{
  lib,
  config,
  ...
}:
let

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;

  cfg = config.scale-network.users.djacu;

in
{

  options.scale-network.users.djacu.enable = mkEnableOption "user djacu";

  config = mkIf cfg.enable {
    users.users = {
      djacu = {
        isNormalUser = true;
        uid = 4269;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbH7DL3UpeYHm+J3YHJTIsnk/vdo5JgEzwD/Bf1tupp yubikey"
        ];
      };
    };
  };

}
