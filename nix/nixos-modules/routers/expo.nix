{ config, lib, ... }:

let
  cfg = config.scale-network.router.expo;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib)
    types
    ;

  inherit (lib.options)
    mkEnableOption
    mkOption
    ;
in
{

  options.scale-network.router.expo = {
    enable = mkEnableOption "SCaLE network expo router setup";
    frrBorderInterface = mkOption {
      type = types.str;
      default = "fiber0";
      description = ''
        FRR broadcast interface to border
      '';
    };
    frrConferenceInterface = mkOption {
      type = types.str;
      default = "fiber1";
      description = ''
        FRR broadcast interface to conference
      '';
    };
  };

  config = mkIf cfg.enable {
    networking.useNetworkd = true;
    systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";

    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

    # must be disabled if using systemd.network
    networking.useDHCP = false;

    systemd.network = {
      enable = true;
      netdevs = {
        "25-bridge901" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge901";
          };
        };
        "25-vlan901" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan901";
          };
          vlanConfig.Id = 901;
        };
        "20-bridge902" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge902";
          };
        };
        "20-vlan902" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan902";
          };
          vlanConfig.Id = 902;
        };
      };
      networks = {
        "30-border" = {
          matchConfig.Name = cfg.frrBorderInterface;
          networkConfig = {
            LinkLocalAddressing = "no";
          };
          vlan = [
            "vlan901"
          ];
        };
        "30-cf" = {
          matchConfig.Name = cfg.frrConferenceInterface;
          networkConfig = {
            LinkLocalAddressing = "no";
          };
          vlan = [
            "vlan902"
          ];
        };
        "40-vlan901" = {
          matchConfig.Name = "vlan901";
          networkConfig = {
            Bridge = "bridge901";
          };
        };
        "40-vlan902" = {
          matchConfig.Name = "vlan902";
          networkConfig = {
            Bridge = "bridge902";
          };
        };
        "50-bridge901" = {
          matchConfig.Name = "bridge901";
          networkConfig.DHCP = false;
          address = [
            "10.1.2.3/24"
          ];
          linkConfig.RequiredForOnline = "routable";
          routes = [
            { Gateway = "10.1.2.1"; }
          ];
        };
        "50-bridge902" = {
          matchConfig.Name = "bridge902";
          networkConfig.DHCP = false;
          address = [
            "10.1.3.3/24"
          ];
        };
      };
    };

    networking.firewall.enable = false;

    scale-network = {
      services.frr.enable = true;
      services.frr.router-id = "10.1.2.3";
      services.frr.broadcast-interface = [
        "bridge901"
        "bridge902"
      ];
    };
  };
}
