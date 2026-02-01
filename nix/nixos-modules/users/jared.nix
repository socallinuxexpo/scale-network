{
  lib,
  config,
  ...
}:
let
  cfg = config.scale-network.users.jared;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.users.jared.enable = mkEnableOption "user jared";

  config = mkIf cfg.enable {
    users.users = {
      jared = {
        isNormalUser = true;
        uid = 4270;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo="
        ];
      };
    };
  };
}
