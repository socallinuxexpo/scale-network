{
  lib,
  config,
  ...
}:
let
  cfg = config.scale-network.users.rhamel;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.users.rhamel.enable = mkEnableOption "user rhamel";

  config = mkIf cfg.enable {
    users.users = {
      rhamel = {
        isNormalUser = true;
        uid = 2010;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICVZ7n1EOezedsbphq5atGtHm11xeGpLZBzEbgV7eZdb",
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBWB23n74TJIPF7QtPrzosSYDbGWX6NvB2tn3aQodcAf"
        ];
      };
    };
  };
}
