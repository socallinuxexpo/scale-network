{
  config,
  pkgs,
  inputs,
  ...
}:
let
  hostname = "monitoring.scale.lan";
  dashboard = pkgs.copyPathToStore ../../../monitoring/openwrt_dashboard.json;
in
{
  boot.kernelParams = [
    "console=ttyS0"
    "boot.shell_on_fail"
  ];

  systemd.network = {
    enable = true;
    networks = {
      "10-lan" = {
        # to match enp0 or eth0
        name = "e*0*";
        enable = true;
        address = [
          "10.0.3.6/24"
          "2001:470:f026:103::6"
        ];
        routes = [
          { routeConfig.Gateway = "10.0.3.1"; }
          { routeConfig.Gateway = "2001:470:f026:103::1"; }
        ];
      };
    };
  };
  networking.hostName = "monitor";
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # TODO: How to handle sudo esculation
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    vim
    git
    bintools
  ];

  services = {
    prometheus = {
      enable = true;
      enableReload = true;
      scrapeConfigs = [
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
    };

    grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = 3000;
          domain = "${hostname}";
        };
        analytics.reporting_enabled = false;
      };
      provision = {
        # Can use just datasources anymore
        # https://github.com/NixOS/nixpkgs/blob/41de143fda10e33be0f47eab2bfe08a50f234267/nixos/modules/services/monitoring/grafana.nix#L101-L104
        datasources.settings.datasources = [
          {
            name = "prometheus";
            uid = "P1809F7CD0C75ACF3";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          }
        ];
        dashboards.settings.providers = [
          {
            name = "openwrt";
            options.path = dashboard;
          }
        ];
      };
    };
    
    loki = {
      enable = true;
      configFile = pkgs.writeText "loki-config.yaml" ''
        auth_enabled: false
      server:
        http_listen_port: 3100

      common:
        ring:
          instance_addr: 127.0.0.1
          kvstore:
            store: inmemory
        replication_factor: 1
        path_prefix: /tmp/loki

      schema_config:
        configs:
          - from: 2020-05-15
            store: tsdb
            object_store: filesystem
            schema: v13
            index:
              prefix: index_
              period: 24h
      storage_config:
        filesyste:
          directory: /tmp/loki/chunks
      '';
    };
    nginx = {
      enable = false;
      # TODO: TLS enabled
      # Good example enable TLS, but would like to keep it out of the /nix/store
      # ref: https://github.com/NixOS/nixpkgs/blob/c6fd903606866634312e40cceb2caee8c0c9243f/nixos/tests/custom-ca.nix#L80
      virtualHosts."${hostname}" = {
        default = true;
        # ACME wont work for us on the private network
        enableACME = false;
        locations."/" = {
          proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}/";
          proxyWebsockets = true;
        };
      };
    };
  };
}
