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
    fqdn = mkOption {
      type = types.str;
      default = "monitoring.scale.lan";
      description = "Publicly facing domain name used to access grafana from a browser";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      80 # nginx-http (redirects to https)
      443 # nginx-https
      14250 # tempo-jaeger-grpc
      14268 # tempo-jaeger-thrift-http
      3000 # grafana-http
      3100 # loki-http
      3200 # mimir-http
      3300 # tempo-http
      4317 # tempo-otlp-grpc
      4318 # tempo-otlp-http
      9095 # loki-grpc
      9096 # mimir-grpc
      9097 # tempo-grpc
    ];

    services = {
      loki = {
        enable = true;

        configuration = {
          auth_enabled = false;

          server = {
            grpc_listen_port = 9095;
            http_listen_port = 3100;
          };

          common = {
            path_prefix = "/var/lib/loki";

            storage = {
              filesystem = {
                chunks_directory = "/var/lib/loki/chunks";
                rules_directory = "/var/lib/loki/rules";
              };
            };

            replication_factor = 1;

            ring = {
              instance_addr = "127.0.0.1";
              kvstore = {
                store = "inmemory";
              };
            };
          };

          schema_config = {
            configs = [
              {
                from = "2024-01-01";
                store = "tsdb";
                object_store = "filesystem";
                schema = "v13";
                index = {
                  prefix = "index_";
                  period = "24h";
                };
              }
            ];
          };
        };
      };

      mimir = {
        enable = true;

        configuration = {
          multitenancy_enabled = false;

          server = {
            grpc_listen_port = 9096;
            http_listen_port = 3200;
          };

          common = {
            storage = {
              backend = "filesystem";
              filesystem = {
                dir = "/var/lib/mimir/data";
              };
            };
          };

          blocks_storage = {
            storage_prefix = "blocks";
            tsdb = {
              dir = "/var/lib/mimir/tsdb";
            };
          };

          compactor = {
            data_dir = "/var/lib/mimir/compactor";
            compaction_interval = "30m";
          };

          ingester = {
            ring = {
              replication_factor = 1;

              kvstore = {
                store = "inmemory";
              };
            };
          };

          ruler_storage = {
            storage_prefix = "ruler";
          };

          limits = {
            ingestion_burst_size = 1000000;
            ingestion_rate = 100000;
            max_global_series_per_user = 300000;
          };

          alertmanager_storage = {
            storage_prefix = "alertmanager";
          };
        };
      };

      tempo = {
        enable = true;

        settings = {
          server = {
            grpc_listen_port = 9097;
            http_listen_port = 3300;
          };

          distributor = {
            receivers = {
              jaeger = {
                protocols = {
                  grpc = {
                    endpoint = "0.0.0.0:14250";
                  };

                  thrift_http = {
                    endpoint = "0.0.0.0:14268";
                  };
                };
              };

              otlp = {
                protocols = {
                  grpc = {
                    endpoint = "0.0.0.0:4317";
                  };

                  http = {
                    endpoint = "0.0.0.0:4318";
                  };
                };
              };
            };
          };

          ingester = {
            max_block_duration = "5m";
          };

          compactor = {
            compaction = {
              block_retention = "48h";
            };
          };

          block_builder = {
            wal = {
              path = "/var/lib/tempo/block-builder/traces";
            };
          };

          storage = {
            trace = {
              backend = "local";

              local = {
                path = "/var/lib/tempo/traces";
              };

              wal = {
                path = "/var/lib/tempo/wal";
              };
            };
          };
        };
      };

      grafana = {
        enable = true;

        settings = {
          server = {
            domain = cfg.fqdn;
            http_addr = "127.0.0.1";
            http_port = 3000;
            protocol = "http";
            root_url = "https://%(domain)s/grafana/";
            serve_from_sub_path = true;
          };
        };

        provision = {
          enable = true;

          datasources.settings.datasources = [
            {
              name = "Loki";
              type = "loki";
              access = "proxy";
              url = "http://127.0.0.1:3100";
            }
            {
              name = "Mimir";
              type = "prometheus";
              access = "proxy";
              url = "http://127.0.0.1:3200/prometheus";
              isDefault = true;
            }
            {
              name = "Tempo";
              type = "tempo";
              access = "proxy";
              url = "http://127.0.0.1:3300";
            }
          ];
        };
      };
    };

    # Standalone SNMP exporter for Juniper switches
    services.prometheus.exporters.snmp = {
      configurationPath = ./snmp-alloy.yml;
      enable = true;
      port = 9116;
    };

    # Enable Alloy for AP, Pi, and switch metrics scraping
    scale-network.services.alloy = {
      enable = true;
      extraConfig = ''
        // File-based service discovery for APs
        discovery.file "aps" {
          files = ["${pkgs.scale-network.scale-inventory}/config/prom-aps.json"]
        }

        // Scrape AP node exporter metrics
        prometheus.scrape "aps" {
          targets = discovery.file.aps.targets
          forward_to = [prometheus.remote_write.mimir.receiver]
          scrape_interval = "15s"
          scrape_timeout = "10s"
          job_name = "aps"
        }

        // File-based service discovery for Pis
        discovery.file "pis" {
          files = ["${pkgs.scale-network.scale-inventory}/config/prom-pis.json"]
        }

        // Scrape Pi node exporter metrics
        prometheus.scrape "pis" {
          targets = discovery.file.pis.targets
          forward_to = [prometheus.remote_write.mimir.receiver]
          scrape_interval = "15s"
          scrape_timeout = "10s"
          job_name = "pis"
        }

        // File-based service discovery for switches (SNMP targets)
        discovery.file "switches" {
          files = ["${pkgs.scale-network.scale-inventory}/config/prom-switches.json"]
        }

        // Relabel switch targets for the standalone SNMP exporter.
        // The SNMP exporter is an HTTP service at 127.0.0.1:9116 that accepts
        // target, module, and auth as query parameters:
        //   GET /snmp?target=[ipv6]:161&module=if_mib,system,jnxOperating&auth=Junitux
        discovery.relabel "switches" {
          targets = discovery.file.switches.targets

          rule {
            source_labels = ["__address__"]
            target_label  = "__param_target"
          }

          rule {
            source_labels = ["__param_target"]
            target_label  = "instance"
          }

          rule {
            target_label = "__param_module"
            replacement  = "if_mib,system,jnxOperating"
          }

          rule {
            target_label = "__param_auth"
            replacement  = "Junitux"
          }

          rule {
            target_label = "__address__"
            replacement  = "127.0.0.1:9116"
          }
        }

        // Scrape SNMP metrics from switches via the standalone SNMP exporter
        prometheus.scrape "switches" {
          targets         = discovery.relabel.switches.output
          forward_to      = [prometheus.remote_write.mimir.receiver]
          scrape_interval = "120s"
          scrape_timeout  = "60s"
          metrics_path    = "/snmp"
          job_name        = "switches"
        }
      '';
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/tempo 0755 tempo tempo"
    ];

    systemd.services.monitoring-selfsigned-cert = {
      description = "Generate self-signed certificate for monitoring";
      wantedBy = [ "multi-user.target" ];
      before = [ "nginx.service" ];
      unitConfig = {
        ConditionPathExists = "!/var/lib/monitoring/ssl/cert.pem";
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mkdir -p /var/lib/monitoring/ssl
        ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 \
          -keyout /var/lib/monitoring/ssl/key.pem \
          -out /var/lib/monitoring/ssl/cert.pem \
          -days 365 -nodes \
          -subj "/CN=${cfg.fqdn}"
        chmod 640 /var/lib/monitoring/ssl/key.pem
        chown root:nginx /var/lib/monitoring/ssl/key.pem
      '';
    };

    services.nginx = {
      enable = mkDefault true;
      recommendedProxySettings = true;
      virtualHosts."${cfg.fqdn}" = {
        default = true;
        forceSSL = true;
        sslCertificate = "/var/lib/monitoring/ssl/cert.pem";
        sslCertificateKey = "/var/lib/monitoring/ssl/key.pem";
        locations."/grafana/" = {
          proxyPass = "http://127.0.0.1:3000";
          proxyWebsockets = true;
        };
        locations."/loki/" = {
          proxyPass = "http://127.0.0.1:3100/";
        };
        locations."/mimir/" = {
          proxyPass = "http://127.0.0.1:3200/";
        };
        locations."/tempo/" = {
          proxyPass = "http://127.0.0.1:3300/";
        };
      };
    };
  };
}
