{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.scale-network.services.alloy;

  inherit
    (lib)
    types
    ;

  inherit
    (lib.modules)
    mkIf
    ;

  inherit
    (lib.options)
    mkEnableOption
    mkOption
    mkPackageOption
    ;

  inherit
    (lib.strings)
    optionalString
    ;

  # Generate the Alloy configuration file
  alloyConfig = pkgs.writeText "config.alloy" ''
    // Prometheus exporter for host metrics (CPU, memory, disk, network, systemd)
    prometheus.exporter.unix "local" {
      enable_collectors = [${lib.concatMapStringsSep ", " (c: "\"${c}\"") cfg.nodeExporter.enableCollectors}]
      disable_collectors = [${lib.concatMapStringsSep ", " (c: "\"${c}\"") cfg.nodeExporter.disableCollectors}]
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
    ${optionalString cfg.loki.enable ''

      // Ship systemd journal logs to Loki
      loki.source.journal "local" {
        forward_to = [loki.write.loki.receiver]
        labels = {
          job = "systemd-journal",
        }
      }

      // Write logs to Loki
      loki.write "loki" {
        endpoint {
          url = "${cfg.loki.url}"
        }
      }
    ''}
    ${optionalString (cfg.extraConfig != "") ''

      // Extra user-provided configuration
      ${cfg.extraConfig}
    ''}
  '';
in {
  options.scale-network.services.alloy = {
    enable = mkEnableOption "SCaLE network Grafana Alloy agent";

    package = mkPackageOption pkgs "grafana-alloy" {};

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

    nodeExporter = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable the node exporter for host metrics";
      };

      enableCollectors = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of collectors to enable";
      };

      disableCollectors = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of collectors to disable";
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
    networking.firewall.allowedTCPPorts = [cfg.httpPort];

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
