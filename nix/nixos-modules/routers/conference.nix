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
        "10-border" = {
          matchConfig.Name = cfg.frrBorderInterface;
          networkConfig.DHCP = false;
          address = [
            "10.1.1.2/24"
          ];
          linkConfig.RequiredForOnline = "routable";
          routes = [
            { Gateway = "10.1.1.1"; }
          ];
        };
        # Physical link to expo
        "10-expo" = {
          matchConfig.Name = cfg.frrExpoInterface;
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
        cfg.frrBorderInterface
        cfg.frrExpoInterface
      ];
    };
  };
}
