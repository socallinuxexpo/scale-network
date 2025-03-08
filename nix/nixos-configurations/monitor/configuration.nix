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
      configuration = {
        server.http_listen_port = 3100;
        server.http_listen_address = "0.0.0.0";
        auth_enabled = false;

        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore = {
                store = "inmemory";
              };
              replication_factor = 1;
            };
          };
          chunk_idle_period = "2h";
          max_chunk_age = "2h";
          chunk_target_size = 1000000;
          chunk_retain_period = "31s";
        };

        schema_config = {
          configs = [{
            from = "2024-10-15";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }];
        };

        storage_config = {
          filesystem = {
            directory = "/var/lib/loki/chunks";
          };
          tsdb_shipper = {
            active_index_directory = "/var/lib/loki/tsdb_index";
            cache_location = "/var/lib/loki/tsdb_cache";
          };
        };

        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "169h";
        };

        table_manager = {
          retention_deletes_enabled = false;
          retention_period = "1s";
        };

        compactor = {
          working_directory = "/var/lib/loki";
          compactor_ring = {
            kvstore = {
              store = "inmemory";
            };
          };
        };
      };
    };


    services.promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 3300;
          grpc_listen_port = 0;
        };
        positions = {
          filename = "/tmp/positions.yaml";
        };
        clients = [{
          url = "http://127.0.0.1:3100/loki/api/v1/push";
        }];
        scrape_configs = [{
          job_name = "nginx-access";
          static_configs = {
            static_configs = [{
              targets = [ "localhost" ];
              labels = {
                __path__ = "/var/log/nginx/access.log";
                job = "nginx-access";
              };
            }];
          }];
        };
      };
    };
    
    nginx = {
      enable = false;
      virtualHosts."grafana" = {
        default = true;
        enableACME = false;
        locations."/" = {
          proxyPass = "http://localhost:3000";
          proxyWebsockets = true;
        };
      };
    };
  };
}
