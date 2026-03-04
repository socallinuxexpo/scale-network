{
  config,
  lib,
  ...
}:
let
  cfg = config.scale-network.services.bindExporter;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.services.bindExporter.enable =
    mkEnableOption "SCaLE network BIND prometheus exporter";

  config = mkIf cfg.enable {
    services.prometheus.exporters.bind = {
      enable = true;
      port = 9119;
      bindURI = "http://127.0.0.1:8053/";
      bindGroups = [
        "server"
        "view"
        "tasks"
      ];
    };
  };
}
