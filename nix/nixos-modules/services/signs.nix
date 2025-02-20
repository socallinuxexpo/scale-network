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


  # TODO(conjones) make an option with a default
  hostname = "monitoring.scale.lan";
in
{
  options.scale-network.services.signs.enable = mkEnableOption "SCaLE signs service";

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 ];
    virtualisation.oci-containers = {
      containers.scale-signs = {
        environmentFiles = [ /var/lib/secrets/scale-sign-secrets.env ];
        image = "sarcasticadmin/scale-signs:1a4fbab";
        ports = [ "8080:80" ];
        extraOptions = [
          "--network=host"
        ];
      };
    };
    virtualHosts."${hostname}" = {
      # ACME wont work for us on the private network
      enableACME = false;
      locations."/" = {
	# TODO(conjones) grab port from config
        proxyPass = "http://localhost:8080";
        proxyWebsockets = true;
      };
    };
  };
}
