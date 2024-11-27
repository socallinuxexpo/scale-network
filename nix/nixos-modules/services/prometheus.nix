{ config, lib, ... }:
let
  cfg = config.scale-network.services.prometheus;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.services.prometheus.enable = mkEnableOption "SCaLE network prometheus exporter";

  config =
    let
      port = 9100;
    in
    mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = [ port ];

      services.prometheus.exporters.node = {
        enable = true;
        port = port;
        enabledCollectors = [
          "logind"
          "systemd"
          "network_route"
        ];
        disabledCollectors = [
          "textfile"
        ];
      };
    };
}
