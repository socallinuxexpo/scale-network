{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.scale-network.services.alloy;

  inherit (lib)
    types
    ;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    mkOption
    mkPackageOption
    ;

  inherit (lib.strings)
    optionalString
    ;

  # Generate glob patterns for accepted log files
  # Each pattern becomes /persist/rsyslog/*/pattern.log
  log_target_list = map
    (pattern: "${cfg.rsyslogdLokiScrape.logPath}/**/${pattern}")
    cfg.rsyslogdLokiScrape.acceptedLogPatterns;

  # Generate the Alloy configuration file
  alloyConfig = pkgs.writeText "config.alloy" ''
    // Prometheus exporter for host metrics (CPU, memory, disk, network, systemd)
    prometheus.exporter.unix "local" {
      enable_collectors = [${
        lib.concatMapStringsSep ", " (c: "\"${c}\"") cfg.nodeExporter.enableCollectors
      }]
      disable_collectors = [${
        lib.concatMapStringsSep ", " (c: "\"${c}\"") cfg.nodeExporter.disableCollectors
      }]
    }

    // Scrape the local unix exporter
    prometheus.scrape "local" {
      targets = prometheus.exporter.unix.local.targets
      forward_to = [prometheus.remote_write.mimir.receiver]
      scrape_interval = "15s"
    }

    // Remote write to Mimir
    prometheus.remote_write "mimir" {
      endpoint {
        url = "${cfg.remoteWrite.url}"
        ${optionalString cfg.remoteWrite.basicAuth.enable ''
          basic_auth {
            username_file = "${cfg.remoteWrite.basicAuth.usernameFile}"
            password_file = "${cfg.remoteWrite.basicAuth.passwordFile}"
          }
        ''}
      }
    }
    ${optionalString cfg.rsyslogdLokiScrape.enable ''
      // Discover rsyslog log files under /persist/rsyslog/<hostname>/
      local.file_match "rsyslog_logs" {
        path_targets = [${
          lib.concatMapStringsSep ", " (tgt: "{\"__path__\" = \"${tgt}\"}") log_target_list
        }]
      }

      // Tail discovered rsyslog log files and forward to Loki
      loki.source.file "rsyslog_logs" {
        targets    = local.file_match.rsyslog_logs.targets
        forward_to = [loki.relabel.rsyslog_logs.receiver]
      }

      // Extract the source hostname from the directory path and add as a label
      loki.relabel "rsyslog_logs" {
        forward_to = [loki.write.loki.receiver]

        rule {
          source_labels = ["filename"]
          regex         = "${cfg.rsyslogdLokiScrape.logPath}/([^/]+)/.*\\.log"
          target_label  = "source_host"
        }

        rule {
          source_labels = ["filename"]
          regex         = ".*/([^/]+)\\.log"
          target_label  = "log_file"
        }

        rule {
          action       = "replace"
          replacement  = "rsyslog"
          target_label = "job"
        }
      }
    ''}
    ${optionalString cfg.loki.enable ''

      // Ship systemd journal logs to Loki
      loki.source.journal "local" {
        forward_to = [loki.write.loki.receiver]
        labels = {
          job = "systemd-journal",
        }
      }
    ''}
    ${optionalString (cfg.loki.enable || cfg.rsyslogdLokiScrape.enable) ''

      // Write logs to Loki
      loki.write "loki" {
        endpoint {
          url = "${cfg.loki.url}"
        }
      }
    ''}
    ${optionalString cfg.keaExporter.enable ''

      // Scrape Kea DHCP exporter
      prometheus.scrape "kea" {
        targets = [{"__address__" = "127.0.0.1:${toString cfg.keaExporter.port}", "instance" = constants.hostname}]
        forward_to = [prometheus.remote_write.mimir.receiver]
        scrape_interval = "15s"
        job_name = "kea"
      }
    ''}
    ${optionalString cfg.bindExporter.enable ''

      // Scrape BIND DNS exporter
      prometheus.scrape "bind" {
        targets = [{"__address__" = "127.0.0.1:${toString cfg.bindExporter.port}", "instance" = constants.hostname}]
        forward_to = [prometheus.remote_write.mimir.receiver]
        scrape_interval = "15s"
        job_name = "bind"
      }
    ''}
    ${optionalString cfg.frrExporter.enable ''

      // Scrape FRR routing exporter
      prometheus.scrape "frr" {
        targets = [{"__address__" = "127.0.0.1:${toString cfg.frrExporter.port}", "instance" = constants.hostname}]
        forward_to = [prometheus.remote_write.mimir.receiver]
        scrape_interval = "15s"
        job_name = "frr"
      }
    ''}
    ${optionalString (cfg.extraConfig != "") ''

      // Extra user-provided configuration
      ${cfg.extraConfig}
    ''}
  '';
in
{
  options.scale-network.services.alloy = {
    enable = mkEnableOption "SCaLE network Grafana Alloy agent";

    package = mkPackageOption pkgs "grafana-alloy" { };

    httpPort = mkOption {
      type = types.port;
      default = 12345;
      description = "Port for the Alloy HTTP API and UI";
    };

    remoteWrite = {
      url = mkOption {
        type = types.str;
        default = "http://127.0.0.1:3200/api/v1/push";
        description = "Mimir remote write endpoint URL";
      };

      basicAuth = {
        enable = mkEnableOption "basic authentication for remote write";

        usernameFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to file containing the username for basic auth";
        };

        passwordFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to file containing the password for basic auth";
        };
      };
    };

    loki = {
      enable = mkEnableOption "log shipping to Loki";

      url = mkOption {
        type = types.str;
        default = "http://127.0.0.1:3100/loki/api/v1/push";
        description = "Loki push endpoint URL";
      };
    };

    rsyslogdLokiScrape = {
      enable = mkEnableOption "scraping rsyslog logs from /persist and shipping to Loki";

      logPath = mkOption {
        type = types.str;
        default = "/persist/rsyslog";
        description = "Base directory where rsyslog stores logs in per-host subdirectories";
      };

      acceptedLogPatterns = mkOption {
        type = types.listOf types.str;
        default = [
          # Observability stack logs
          "alloy.log"
          "loki.log"
          # "mimir.log" # ... pretty big > 2gb
          # "tempo.log" # not used now
          # "grafana-start.log" # is this useful for loki if grafana issues

          # Service-specific exporters
          "bind_exporter.log"
          "kea-exporter.log"
          "snmp_exporter.log"

          # Core network services
          "named.log"          # DNS server
          "kea-ctrl-agent.log" # DHCP control
          "kea-dhcp4.log"      # DHCPv4
          "kea-dhcp6.log"      # DHCPv6
          "wasgehtd.log"       # Custom monitoring

          # Switch logs (Juniper)
          "kernel.log"         # Switch kernel messages
          "eventd.log"         # Switch events
          "pfed.log"           # Packet forwarding engine
          "rpd.log"            # Routing protocol daemon

          # Access point logs (OpenWRT)
          "hostapd.log"        # WiFi authentication
          "netifd.log"         # Network interface daemon
          "apinger.log"        # AP monitoring

          # Catch-all messages (can be massive)
          # "messages.log"     # Uncomment if needed, but note it can be very large
        ];
        description = ''
          List of log file patterns to scrape from each host directory.
          Supports glob patterns (e.g., "kea-*.log").

          Notably excluded by default:
          - sshd*.log (too verbose)
          - stats-*.log (AP metrics, better handled differently)
          - messages.log (can be multi-GB, uncomment if critical)
        '';
      };
    };

    nodeExporter = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable the node exporter for host metrics";
      };

      enableCollectors = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of collectors to enable";
      };

      disableCollectors = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of collectors to disable";
      };
    };

    keaExporter = {
      enable = mkEnableOption "Alloy scraping of local Kea DHCP exporter";

      port = mkOption {
        type = types.port;
        default = 9547;
        description = "Port of the local Kea exporter";
      };
    };

    bindExporter = {
      enable = mkEnableOption "Alloy scraping of local BIND DNS exporter";

      port = mkOption {
        type = types.port;
        default = 9119;
        description = "Port of the local BIND exporter";
      };
    };

    frrExporter = {
      enable = mkEnableOption "Alloy scraping of local FRR routing exporter";

      port = mkOption {
        type = types.port;
        default = 9342;
        description = "Port of the local FRR exporter";
      };
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additional Alloy configuration blocks to append";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Environment file for secrets (loaded by systemd)";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ cfg.httpPort ];

    services.alloy = {
      enable = true;
      configPath = alloyConfig;
      extraFlags = [
        "--server.http.listen-addr=0.0.0.0:${toString cfg.httpPort}"
      ];
    };

    systemd.services.alloy = mkIf (cfg.environmentFile != null) {
      serviceConfig.EnvironmentFile = cfg.environmentFile;
    };
  };
}
