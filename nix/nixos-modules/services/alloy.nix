{
  config,
  lib,
  ...
}:
let
  cfg = config.scale-network.services.alloy;

  inherit (lib)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    mkOption
    ;
in
{
  options.scale-network.services.alloy = {
    enable = mkEnableOption "SCaLE network Alloy Metrics Collector";
    prometheusEndpoint = mkOption "URL to prometheus/mimir server" {
      type = type.str;
    };
    lokiEndpoint = mkOption "URL to loki server" {
      type = type.str;
    };
    alloyConfig = mkOption {
      type = type.str;
      default = ''
        logging {
            level  = "debug"
            format = "logfmt"
        }
        prometheus.exporter.unix "local_system" { }
        
        prometheus.scrape "scrape_metrics" {
            targets         = prometheus.exporter.unix.local_system.targets
            forward_to      = [prometheus.relabel.filter_metrics.receiver]
            scrape_interval = "10s"
        }


      '';
      description = "Alloy configuration for collecting metrics"
    };
    alloyLogs = mkOption {
      type = type.listOf attrs;
      default = [
        {
            path = "/var/lib/syslog";
            sync_period = "5s";
            filter = "";
        }
      ];
    };
    extraFlags = mkOption {
      type = type.listOf str;
      default = [ ];
    };
  };

  let
    prometheusEndpoint = writeText ''
      prometheus.remote_write "mimir" {
         endpoint {
          url = "${cfg.prometheusEndpoint}"
         }
      }
    '';
    lokiEndpoint = writeText ''
      loki.write "grafana_loki" {
        endpoint {
          url = "${cfg.lokiEndpoint}"
        }
      }
    '';
  in
  config = mkIf cfg.enable {
    alloyConfig = concatText "config.alloy" [
      cfg.alloyConfig
      cfg.alloyLogs 
      prometheusEndpoint
      lokiEndpoint
    ];
    services.alloy = {
      enable = true;
      configPath = alloyConfig;
      extraFlags = cfg.extraFlags
    };
  };
}
