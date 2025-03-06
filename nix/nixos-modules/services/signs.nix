{
  config,
  lib,
  ...
}:
let
  cfg = config.scale-network.services.signs;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.services.signs.enable = mkEnableOption "SCaLE signs service";

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 ];
    virtualisation.oci-containers = {
      containers.scale-signs = {
        image = "sarcasticadmin/scale-signs:1a4fbab";
        ports = [ "80:80" ];
        extraOptions = [
          "--network=host"
        ];
      };
    };
  };
}
