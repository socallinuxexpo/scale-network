{
  config,
  lib,
  ...
}:
let
  cfg = config.scale-network.services.keaExporter;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.services.keaExporter.enable =
    mkEnableOption "SCaLE network Kea DHCP prometheus exporter";

  config = mkIf cfg.enable {
    services.prometheus.exporters.kea = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9547;
      targets = [
        "/run/kea/kea-dhcp4-ctrl.sock"
        "/run/kea/kea-dhcp6-ctrl.sock"
      ];
    };
  };
}
