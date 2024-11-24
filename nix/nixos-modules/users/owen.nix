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
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBjjcUJLTENGrV6K/nrPOswcBVMMuS4sLSs0UyTRw8wU87PDUzJz8Ht2SgHqeEQJdRm1+b6iLsx2uKOf+/pU8qE= root@kiev.delong.com"
        ];
      };
    };
  };
}
