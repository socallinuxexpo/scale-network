{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.scale-network.services.monitoring;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.services.monitoring.enable = mkEnableOption "SCaLE network monitoring server";
  options.scale-network.services.monitoring.grafanaDomain = mkOption {
    type = types.str;
    default = "localhost";
    description = "Publicly facing domain name used to access grafana from a browser";
  };

  config =
    let
      openwrt-dashboard = pkgs.copyPathToStore ../../../monitoring/openwrt_dashboard.json;
    in
    mkIf cfg.enable {

      prometheus.enable = true;
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
      ];

      grafana.enable = config.monitoring.grafanaEnable;
      grafana.settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = 3000;
          domain = config.monitoring.grafanaDomain;
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
            options.path = openwrt-dashboard;
          }
        ];
      };

      nginx.enable = false;
      # TODO: TLS enabled
      # Good example enable TLS, but would like to keep it out of the /nix/store
      # ref: https://github.com/NixOS/nixpkgs/blob/c6fd903606866634312e40cceb2caee8c0c9243f/nixos/tests/custom-ca.nix#L80
      nginx.virtualHosts."${config.networking.hostname}" = {
        default = true;
        enableACME = false;
        locations."/".proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}/";
        proxyWebsockets = true;
      };
    };
}
