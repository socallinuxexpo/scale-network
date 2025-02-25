{
  config,
  lib,
  ...
}:
let
  cfg = config.scale-network.services.signs;

  inherit (lib)
    types
    ;

  inherit (lib.modules)
    mkDefault
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    mkOption
    ;
in
{
  options.scale-network.services.signs = {
    enable = mkEnableOption "SCaLE signs service";
    nginxFQDN = mkOption {
      type = types.str;
      default = "signs.scale.lan";
      description = "Publicly facing domain name used to access grafana from a browser";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 ];
    virtualisation.oci-containers = {
      containers.scale-signs = {
        image = "sarcasticadmin/scale-signs:1a4fbab";
        ports = [ "8080:80" ];
        extraOptions = [
          "--network=host"
        ];
      };
    };

    services.nginx.enable = mkDefault true;
    services.nginx.virtualHosts."${cfg.nginxFQDN}" = {
      default = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080/";
      };
    };
  };
}
