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
      port = 9547;
      targets = [
        "http://127.0.0.1:8000"
      ];
    };
  };
}
