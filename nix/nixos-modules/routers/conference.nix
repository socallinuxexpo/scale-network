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
        "501"
        "502"
        "503"
        "504"
        "505"
        "506"
        "507"
      ];
    };

    systemd.network = {
      enable = true;
      netdevs = {
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
        # 501 (SCALE-FAST)
        "20-vlan501" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan501";
          };
          vlanConfig.Id = 501;
        };
        "25-bridge501" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge501";
          };
        };
        # 502 (SCALE-Speaker)
        "20-vlan502" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan502";
          };
          vlanConfig.Id = 502;
        };
        "25-bridge502" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge502";
          };
        };
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
        # cfCTF
        "20-vlan504" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan504";
          };
          vlanConfig.Id = 504;
        };
        "25-bridge504" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge504";
          };
        };
        # cfAVLAN Audio Visual
        "20-vlan505" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan505";
          };
          vlanConfig.Id = 505;
        };
        "25-bridge505" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge505";
          };
        };
        # cfNOC
        "20-vlan506" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan506";
          };
          vlanConfig.Id = 506;
        };
        "25-bridge506" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge506";
          };
        };
        # cfSigns
        "20-vlan507" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan507";
          };
          vlanConfig.Id = 507;
        };
        "25-bridge507" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge507";
          };
        };
        "25-vlan900" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan900";
          };
          vlanConfig.Id = 900;
        };
        "25-bridge900" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge900";
          };
        };
        "20-vlan902" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan902";
          };
          vlanConfig.Id = 902;
        };
        "20-bridge902" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge902";
          };
        };
      };
      # Physical link to border
      networks = {
        "30-copper0" = {
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
            "vlan501"
            "vlan502"
            "vlan503"
            "vlan504"
            "vlan505"
            "vlan506"
            "vlan507"
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
        # ExScaleFast
        "40-vlan501" = {
          matchConfig.Name = "vlan501";
          networkConfig = {
            Bridge = "bridge501";
          };
        };
        "50-bridge501" = {
          matchConfig.Name = "bridge501";
          enable = true;
          address = [
            "10.128.136.1/21"
            "2001:470:f026:501::1/64"
          ];
        };
        # ExSpeaker
        "40-vlan502" = {
          matchConfig.Name = "vlan502";
          networkConfig = {
            Bridge = "bridge502";
          };
        };
        "50-bridge502" = {
          matchConfig.Name = "bridge502";
          enable = true;
          address = [
            "10.128.2.1/21"
            "2001:470:f026:502::1/64"
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
        "40-vlan504" = {
          matchConfig.Name = "vlan504";
          networkConfig = {
            Bridge = "bridge504";
          };
        };
        "50-bridge504" = {
          matchConfig.Name = "bridge504";
          enable = true;
          address = [
            "10.128.4.1/24"
            "2001:470:f026:504::1/64"
          ];
        };
        "40-vlan505" = {
          matchConfig.Name = "vlan505";
          networkConfig = {
            Bridge = "bridge505";
          };
        };
        "50-bridge505" = {
          matchConfig.Name = "bridge505";
          enable = true;
          address = [
            "10.128.5.1/24"
            "2001:470:f026:505::1/64"
          ];
        };
        "40-vlan506" = {
          matchConfig.Name = "vlan506";
          networkConfig = {
            Bridge = "bridge506";
          };
        };
        "50-bridge506" = {
          matchConfig.Name = "bridge506";
          enable = true;
          address = [
            "10.128.6.1/24"
            "2001:470:f026:506::1/64"
          ];
        };
        "40-vlan507" = {
          matchConfig.Name = "vlan507";
          networkConfig = {
            Bridge = "bridge507";
          };
        };
        "50-bridge507" = {
          matchConfig.Name = "bridge507";
          enable = true;
          address = [
            "10.128.7.1/24"
            "2001:470:f026:507::1/64"
          ];
        };
        "30-${cfg.frrBorderInterface}" = {
          matchConfig.Name = cfg.frrBorderInterface;
          networkConfig = {
            LinkLocalAddressing = "no";
          };
          vlan = [
            "vlan900"
          ];
        };
        "30-${cfg.frrExpoInterface}" = {
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
        # excluding bridge507 (cfSigns) since
        # its a ipv6 only network
        downstreamInterfaces = [
          "bridge500"
          "bridge501"
          "bridge502"
          "bridge504"
          "bridge506"
        ];
        upstreamInterfaces = [ "bridge503" ];
        dhcpServerIps = [ "10.128.3.20" ];
      };
    };

  };
}
