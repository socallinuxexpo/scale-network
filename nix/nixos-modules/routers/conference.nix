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

    systemd.network = {
      enable = true;
      netdevs = {
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
        "bridge900"
        "bridge902"
      ];
    };
  };
}
