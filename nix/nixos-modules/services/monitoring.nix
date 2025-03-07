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
          static_configs = [
            {
              targets = [
                "noc.scale.lan"
                "confidf.scale.lan"
                "nw-idf.scale.lan"
                "ne-idf.scale.lan"
                "expoidf.scale.lan"
                "expo-catwalk.scale.lan"
                "massflash.scale.lan"
                "avswitch.scale.lan"
                "deceased1.scale.lan"
                "rm211.scale.lan"
                "rm214.scale.lan"
                "deceased3.scale.lan"
                "rm103.scale.lan"
                "rm104.scale.lan"
                "rm105.scale.lan"
                "rm106.scale.lan"
                "rm107.scale.lan"
                "sparea.scale.lan"
                "spareb.scale.lan"
                "sparec.scale.lan"
                "spared.scale.lan"
                "sparee.scale.lan"
                "sparef.scale.lan"
                "expoaw.scale.lan"
                "expoa1.scale.lan"
                "expoa2.scale.lan"
                "expoa3.scale.lan"
                "expoa4.scale.lan"
                "expoa5.scale.lan"
                "expob1.scale.lan"
                "expob2.scale.lan"
                "expob3.scale.lan"
                "expob4.scale.lan"
                "expob5.scale.lan"
                "expoc1.scale.lan"
                "expoc2.scale.lan"
                "expoc3.scale.lan"
                "expoc4.scale.lan"
                "expoc5.scale.lan"
                "ballrooma.scale.lan"
                "ballroomb.scale.lan"
                "ballroomc.scale.lan"
                "ballroomde.scale.lan"
                "ballroomf.scale.lan"
                "ballroomg.scale.lan"
                "deceased2.scale.lan"
                "rm209-210.scale.lan"
                "rm101-102.scale.lan"
                "ballroomh.scale.lan"
                "rm208.scale.lan"
                "donotuse.scale.lan"
                "regdesk.scale.lan"
                "br-mdf-01.scale.lan"
                "ex-mdf-01.scale.lan"
                "cf-mdf-01.scale.lan"
              ];
            }
          ];
          metrics_path = "/snmp";
          params = {
            auth = [ "Junitux" ];
            module = [ "juniper" ];
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
