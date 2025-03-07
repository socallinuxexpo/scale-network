{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.scale-network.services.monitoring;

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

  unfilteredList = (
    builtins.split "\n" (
      builtins.readFile "${pkgs.scale-network.scaleInventory}/config/all-network-devices"
    )
  );
  filteredList = (builtins.filter (line: line != [ ] && line != "") unfilteredList);
in
{
  options.scale-network.services.monitoring = {
    enable = mkEnableOption "SCaLE network monitoring server";
    nginxFQDN = mkOption {
      type = types.str;
      default = "monitoring.scale.lan";
      description = "Publicly facing domain name used to access grafana from a browser";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    services = {
      prometheus.enable = mkDefault true;
      prometheus.enableReload = true;
      prometheus.scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [
            {
              targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
              labels = {
                instance = "localhost";
              };
            }
          ];
        }
        {
          job_name = "ap";
          static_configs = builtins.fromJSON (
            builtins.readFile "${pkgs.scale-network.scaleInventory}/config/prom.json"
          );
        }
        {
          job_name = "wasgeht";
          static_configs = [
            {
              targets = [ "localhost:${toString config.scale-network.services.wasgeht.port}" ];
            }
          ];
        }
        {
          job_name = "snmp";
          scrape_timeout = "115s";
          scrape_interval = "2m";
          static_configs = [
            {
              targets = filteredList;
            }
          ];
          metrics_path = "/snmp";
          params = {
            auth = [ "Junitux" ];
            module = [
              "if_mib"
              "system"
            ];
          };
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = "127.0.0.1:9116";
            }
          ];
        }
        {
          job_name = "snmp-srx";
          scrape_timeout = "115s";
          scrape_interval = "2m";
          static_configs = [
            {
              targets = ["br-mdf-01.scale.lan"];
            }
          ];
          metrics_path = "/snmp";
          params = {
            auth = [ "Junitux" ];
            module = [
              "junos_bandwidth"
            ];
          };
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = "127.0.0.1:9116";
            }
          ];
        }
      ];
      prometheus.exporters.snmp = {
        enable = true;
        configurationPath = ./snmp.yml;
      };

      grafana.enable = mkDefault true;
      grafana.settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = 3000;
          domain = "${cfg.nginxFQDN}";
        };
        analytics.reporting_Enabled = false;
      };
      grafana.provision.datasources.settings = {
        datasources = [
          {
            name = "prometheus";
            uid = "P1809F7CD0C75ACF3";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          }
        ];
      };
      grafana.provision.dashboards.settings = {
        providers = [
          {
            name = "openwrt";
            options.path = ../../../monitoring/openwrt_dashboard.json;
          }
        ];
      };

      nginx.enable = mkDefault true;
      nginx.recommendedProxySettings = true;
      # TODO: TLS enabled
      # Good example enable TLS, but would like to keep it out of the /nix/store
      # ref: https://github.com/NixOS/nixpkgs/blob/c6fd903606866634312e40cceb2caee8c0c9243f/nixos/tests/custom-ca.nix#L80
      nginx.virtualHosts."${cfg.nginxFQDN}" = {
        default = false;
        enableACME = false;
        locations."/" = {
          proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}/";
        };
        locations."/api/live" = {
          proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}/";
          proxyWebsockets = true;
        };
      };
    };
  };
}
