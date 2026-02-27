{ config, lib, ... }:

let
  cfg = config.scale-network.router.expo;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib)
    types
    ;

  inherit (lib.attrsets)
    listToAttrs
    nameValuePair
    ;

  inherit (lib.options)
    mkEnableOption
    mkOption
    ;

  genAttrs' = xs: f: listToAttrs (map f xs);
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
    trunkInterfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Trunk Interfaces
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
        "100"
        "101"
        "102"
        "103"
        "104"
        "105"
        "107"
        "110"
      ];
    };

    systemd.network = {
      enable = true;
      netdevs = {
        # exSCALE-SLOW
        "25-bridge100" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge100";
          };
        };
        "25-vlan100" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan100";
          };
          vlanConfig.Id = 100;
        };
        # exSCALE-FAST
        "25-bridge101" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge101";
          };
        };
        "25-vlan101" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan101";
          };
          vlanConfig.Id = 101;
        };
        # exSpeaker
        "25-bridge102" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge102";
          };
        };
        "25-vlan102" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan102";
          };
          vlanConfig.Id = 102;
        };
        # exInfra
        "25-bridge103" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge103";
          };
        };
        "25-vlan103" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan103";
          };
          vlanConfig.Id = 103;
        };
        # exMDF
        # TODO: Talk to owen to see if still needed
        # goes to ExpoB1
        "25-bridge104" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge104";
          };
        };
        "25-vlan104" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan104";
          };
          vlanConfig.Id = 104;
        };
        # exAVLAN
        "25-bridge105" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge105";
          };
        };
        "25-vlan105" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan105";
          };
          vlanConfig.Id = 105;
        };
        # exSigns
        "25-bridge107" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge107";
          };
        };
        "25-vlan107" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan107";
          };
          vlanConfig.Id = 107;
        };
        # exRegistration
        "25-bridge110" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge110";
          };
        };
        "25-vlan110" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan110";
          };
          vlanConfig.Id = 110;
        };
        "25-bridge902" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge902";
          };
        };
        "25-vlan902" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan902";
          };
          vlanConfig.Id = 902;
        };
        "20-bridge903" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge903";
          };
        };
        "20-vlan903" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan903";
          };
          vlanConfig.Id = 903;
        };
      };
      networks =
        let
          trunks =
            interface:
            nameValuePair "30-${interface}" {
              matchConfig.Name = "${interface}";
              linkConfig = {
                RequiredForOnline = "carrier";
              };
              networkConfig = {
                LinkLocalAddressing = "no";
              };
              # tag vlan on this link
              vlan = [
                "vlan100"
                "vlan101"
                "vlan102"
                "vlan103"
                "vlan104"
                "vlan105"
                "vlan107"
                "vlan110"
              ];
            };

        in
        genAttrs' cfg.trunkInterfaces trunks
        // {
          "30-${cfg.frrBorderInterface}" = {
            matchConfig.Name = cfg.frrBorderInterface;
            networkConfig = {
              LinkLocalAddressing = "no";
            };
            vlan = [
              "vlan902"
            ];
          };
          "30-${cfg.frrConferenceInterface}" = {
            matchConfig.Name = cfg.frrConferenceInterface;
            networkConfig = {
              LinkLocalAddressing = "no";
            };
            vlan = [
              "vlan903"
            ];
          };
          "40-vlan100" = {
            matchConfig.Name = "vlan100";
            networkConfig = {
              Bridge = "bridge100";
            };
          };
          "50-bridge100" = {
            matchConfig.Name = "bridge100";
            enable = true;
            address = [
              "10.0.128.1/21"
              "2001:470:f026:100::1/64"
            ];
          };
          "40-vlan101" = {
            matchConfig.Name = "vlan101";
            networkConfig = {
              Bridge = "bridge101";
            };
          };
          "50-bridge101" = {
            matchConfig.Name = "bridge101";
            enable = true;
            address = [
              "10.0.136.1/21"
              "2001:470:f026:101::1/64"
            ];
          };
          "40-vlan102" = {
            matchConfig.Name = "vlan102";
            networkConfig = {
              Bridge = "bridge102";
            };
          };
          "50-bridge102" = {
            matchConfig.Name = "bridge102";
            enable = true;
            address = [
              "10.0.2.1/24"
              "2001:470:f026:102::1/64"
            ];
          };
          "40-vlan103" = {
            matchConfig.Name = "vlan103";
            networkConfig = {
              Bridge = "bridge103";
            };
          };
          "50-bridge103" = {
            matchConfig.Name = "bridge103";
            enable = true;
            address = [
              "10.0.3.1/24"
              "2001:470:f026:103::1/64"
            ];
          };
          "40-vlan104" = {
            matchConfig.Name = "vlan104";
            networkConfig = {
              Bridge = "bridge104";
            };
          };
          "50-bridge104" = {
            matchConfig.Name = "bridge104";
            enable = true;
            address = [
              "10.0.4.2/24"
              "2001:470:f026:104::1/64"
            ];
          };
          "40-vlan105" = {
            matchConfig.Name = "vlan105";
            networkConfig = {
              Bridge = "bridge105";
            };
          };
          "50-bridge105" = {
            matchConfig.Name = "bridge105";
            enable = true;
            address = [
              "10.0.5.1/24"
              "2001:470:f026:105::1/64"
            ];
          };
          "40-vlan107" = {
            matchConfig.Name = "vlan107";
            networkConfig = {
              Bridge = "bridge107";
            };
          };
          "50-bridge107" = {
            matchConfig.Name = "bridge107";
            enable = true;
            address = [
              "2001:470:f026:107::1/64"
            ];
          };
          "40-vlan110" = {
            matchConfig.Name = "vlan110";
            networkConfig = {
              Bridge = "bridge110";
            };
          };
          "50-bridge110" = {
            matchConfig.Name = "bridge110";
            enable = true;
            address = [
              "10.0.10.1/24"
              "2001:470:f026:110::1/64"
            ];
          };
          "40-vlan902" = {
            matchConfig.Name = "vlan902";
            networkConfig = {
              Bridge = "bridge902";
            };
          };
          "50-bridge902" = {
            matchConfig.Name = "bridge902";
            networkConfig.DHCP = false;
            address = [
              "172.20.2.3/24"
              "2001:470:f026:902::3/64"
            ];
            linkConfig.RequiredForOnline = "routable";
            routes = [
              { Gateway = "172.20.2.1"; }
            ];
          };
          "40-vlan903" = {
            matchConfig.Name = "vlan903";
            networkConfig = {
              Bridge = "bridge903";
            };
          };
          "50-bridge903" = {
            matchConfig.Name = "bridge903";
            networkConfig.DHCP = false;
            address = [
              "172.20.3.3/24"
              "2001:470:f026:903::3/64"
            ];
          };
        };
    };

    networking.firewall.enable = false;

    scale-network = {
      services.frr.enable = true;
      services.frr.router-id = "172.20.2.3";
      services.frr.broadcast-interface = [
        "bridge902" # border
        "bridge903" # conf
      ];
      services.frr.passive-interface = [
        "bridge100"
        "bridge101"
        "bridge102"
        "bridge105"
        "bridge107"
        "bridge110"
      ];

      services.dhcp4-relay = {
        # no AV dhcp6-relay because dhcp server on the same subnet (105)
        # as its clients
        "tech" = {
          enable = true;
          # excluding bridge107 (exSigns) since
          # its a ipv6 only network
          downstreamInterfaces = [
            "bridge100"
            "bridge101"
            "bridge102"
            "bridge104"
            "bridge110"
          ];
          upstreamInterfaces = [ "bridge103" ];
          dhcpServerIps = [ "10.0.3.20" ];
        };
      };
      # must use to %% to escape the % expansion by systemd
      services.dhcp6-relay = {
        # no AV dhcp6-relay because dhcp server on the same subnet (105)
        # as its clients
        "tech" = {
          enable = true;
          downstreamInterfaces = [
            "2001:470:f026:100::1%%bridge100"
            "2001:470:f026:101::1%%bridge101"
            "2001:470:f026:102::1%%bridge102"
            "2001:470:f026:104::1%%bridge104"
            "2001:470:f026:107::1%%bridge107"
            "2001:470:f026:110::1%%bridge110"
          ];
          upstreamInterfaces = [ "2001:470:f026:103::20%%bridge103" ];
        };
      };
    };
  };
}
