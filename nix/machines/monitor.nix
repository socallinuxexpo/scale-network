{ config, lib, pkgs, inputs, ... }:
let
  hostname = "monitoring.scale.lan";
in
{
  imports =
    [
      ./_common/prometheus.nix
    ];

  boot.kernelParams = [ "console=ttyS0" "boot.shell_on_fail" ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # TODO: How to handle sudo esculation
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    vim
    git
    bintools
  ];

  services = {
    openssh = {
      enable = true;
    };

    prometheus = {
      enable = true;
      enableReload = true;
      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [
            {
              targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
              labels = { instance = "localhost"; };
            }
          ];
        }
        {
          job_name = "ap";
          static_configs = builtins.fromJSON (builtins.readFile "${inputs.self.packages.${pkgs.system}.scaleInventory}/config/prom.json");
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
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          }
        ];
      };
    };

    nginx = {
      enable = true;
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
