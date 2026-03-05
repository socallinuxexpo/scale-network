{
  config,
  lib,
  ...
}:
let
  cfg = config.scale-network.services.frrExporter;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.services.frrExporter.enable =
    mkEnableOption "SCaLE network FRR prometheus exporter";

  config = mkIf cfg.enable {
    services.prometheus.exporters.frr = {
      enable = true;
      port = 9342;
    };
  };
}
