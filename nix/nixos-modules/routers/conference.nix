{
  config,
  lib,
  ...
}:

let
  cfg = config.scale-network.router.conference;

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

  options.scale-network.router.conference = {
    enable = mkEnableOption "SCaLE network conference router setup";
    frrBorderInterface = mkOption {
      type = types.str;
      default = "fiber0";
      description = ''
        FRR broadcast interface to border
      '';
    };
    frrExpoInterface = mkOption {
      type = types.str;
      default = "fiber1";
      description = ''
        FRR broadcast interface to expo
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

    scale-network.router.radvd = {
      enable = true;
      vlans = [
        "500"
        "503"
      ];
    };

    systemd.network = {
      enable = true;
      netdevs = {
        # confInfra
        "20-vlan503" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan503";
          };
          vlanConfig.Id = 503;
        };
        "25-bridge503" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge503";
          };
        };
        # conf2.4
        "20-vlan500" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan500";
          };
          vlanConfig.Id = 500;
        };
        "25-bridge500" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge500";
          };
        };
        "25-bridge900" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge900";
          };
        };
        "25-vlan900" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan900";
          };
          vlanConfig.Id = 900;
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
      # Physical link to border
      networks = {
        "30-trunk" = {
          # TODO probably make this a map of interfaces for trunking
          matchConfig.Name = "copper0";
          linkConfig = {
            RequiredForOnline = "carrier";
          };
          networkConfig = {
            LinkLocalAddressing = "no";
          };
          # tag vlan on this link
          vlan = [
            "vlan500"
            "vlan503"
          ];
        };
        "40-vlan503" = {
          matchConfig.Name = "vlan503";
          networkConfig = {
            Bridge = "bridge503";
          };
        };
        "50-bridge503" = {
          matchConfig.Name = "bridge503";
          enable = true;
          address = [
            "10.128.3.1/24"
            "2001:470:f026:503::1/64"
          ];
        };
        "40-vlan500" = {
          matchConfig.Name = "vlan500";
          networkConfig = {
            Bridge = "bridge500";
          };
        };
        "50-bridge500" = {
          matchConfig.Name = "bridge500";
          enable = true;
          address = [
            "10.128.128.1/21"
            "2001:470:f026:500::1/64"
          ];
        };
        "30-border" = {
          matchConfig.Name = cfg.frrBorderInterface;
          networkConfig = {
            LinkLocalAddressing = "no";
          };
          vlan = [
            "vlan900"
          ];
        };
        "30-expo" = {
          matchConfig.Name = cfg.frrExpoInterface;
          networkConfig = {
            LinkLocalAddressing = "no";
          };
          vlan = [
            "vlan902"
          ];
        };
        "40-vlan900" = {
          matchConfig.Name = "vlan900";
          networkConfig = {
            Bridge = "bridge900";
          };
        };
        "40-vlan902" = {
          matchConfig.Name = "vlan902";
          networkConfig = {
            Bridge = "bridge902";
          };
        };
        "50-bridge900" = {
          matchConfig.Name = "bridge900";
          networkConfig.DHCP = false;
          address = [
            "10.1.1.2/24"
          ];
          linkConfig.RequiredForOnline = "routable";
          routes = [
            { Gateway = "10.1.1.1"; }
          ];
        };
        "50-bridge902" = {
          matchConfig.Name = "bridge902";
          networkConfig.DHCP = false;
          address = [
            "10.1.3.2/24"
          ];
        };
      };
    };

    networking.firewall.enable = false;

    scale-network = {
      services.frr.enable = true;
      services.frr.router-id = "10.1.1.2";
      services.frr.broadcast-interface = [
        "bridge900" # border
        "bridge902" # expo
      ];
      services.dhcp4-relay."tech" = {
        enable = true;
        downstreamInterfaces = [ "bridge500" ];
        upstreamInterfaces = [ "bridge503" ];
        dhcpServerIps = [ "10.128.3.20" ];
      };
    };

  };
}
