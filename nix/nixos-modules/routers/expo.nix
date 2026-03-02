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

  trunkVlans = [
    100
    101
    102
    103
    105
    107
    110
  ];
  borderVlans = [
    103
    104
  ];
  conferenceVlans = [ 903 ];

  # Generate a VLAN netdev named vlan{id}{interface}
  mkVlanNetdev =
    vlanId: interface:
    nameValuePair "25-vlan${toString vlanId}-${interface}" {
      netdevConfig = {
        Kind = "vlan";
        Name = "vlan${toString vlanId}${interface}";
      };
      vlanConfig.Id = vlanId;
    };

  # Generate a network binding: vlan{id}{interface} → bridge{id}
  mkVlanBridgeNetwork =
    vlanId: interface:
    nameValuePair "40-vlan${toString vlanId}${interface}" {
      matchConfig.Name = "vlan${toString vlanId}${interface}";
      networkConfig.Bridge = "bridge${toString vlanId}";
    };

  # Generate netdevs for all (vlanId, interface) combinations
  mkVlanNetdevs =
    vlans: interfaces:
    listToAttrs (builtins.concatMap (iface: map (id: mkVlanNetdev id iface) vlans) interfaces);

  # Generate network bindings for all (vlanId, interface) combinations
  mkVlanBridgeNetworks =
    vlans: interfaces:
    listToAttrs (builtins.concatMap (iface: map (id: mkVlanBridgeNetwork id iface) vlans) interfaces);
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
        # exSCALE-FAST
        "25-bridge101" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge101";
          };
        };
        # exSpeaker
        "25-bridge102" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge102";
          };
        };
        # exInfra
        "25-bridge103" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge103";
          };
        };
        # exMDF (conf building router vlan)
        "25-bridge104" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge104";
          };
        };
        # exAVLAN
        "25-bridge105" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge105";
          };
        };
        # exSigns
        "25-bridge107" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge107";
          };
        };
        # exRegistration
        "25-bridge110" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge110";
          };
        };
        "25-bridge903" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "bridge903";
          };
        };
      }
      // mkVlanNetdevs trunkVlans cfg.trunkInterfaces
      // mkVlanNetdevs borderVlans [ cfg.frrBorderInterface ]
      // mkVlanNetdevs conferenceVlans [ cfg.frrConferenceInterface ];
      networks =
        let
          trunks =
            interface:
            nameValuePair "30-${interface}" {
              matchConfig.Name = "${interface}";
              linkConfig = {
                RequiredForOnline = "no-carrier";
              };
              networkConfig = {
                LinkLocalAddressing = "no";
                LLDP = true;
                EmitLLDP = true;
              };
              # tag vlan on this link
              vlan = map (id: "vlan${toString id}${interface}") trunkVlans;
            };

        in
        genAttrs' cfg.trunkInterfaces trunks
        // mkVlanBridgeNetworks trunkVlans cfg.trunkInterfaces
        // mkVlanBridgeNetworks borderVlans [ cfg.frrBorderInterface ]
        // mkVlanBridgeNetworks conferenceVlans [ cfg.frrConferenceInterface ]
        // {
          "30-${cfg.frrBorderInterface}" = {
            matchConfig.Name = cfg.frrBorderInterface;
            networkConfig = {
              LinkLocalAddressing = "no";
              LLDP = true;
              EmitLLDP = true;
            };
            vlan = map (id: "vlan${toString id}${cfg.frrBorderInterface}") borderVlans;
          };
          "30-${cfg.frrConferenceInterface}" = {
            matchConfig.Name = cfg.frrConferenceInterface;
            networkConfig = {
              LinkLocalAddressing = "no";
              LLDP = true;
              EmitLLDP = true;
            };
            vlan = map (id: "vlan${toString id}${cfg.frrConferenceInterface}") conferenceVlans;
          };
          "50-bridge100" = {
            matchConfig.Name = "bridge100";
            enable = true;
            address = [
              "10.0.128.1/21"
              "2001:470:f026:100::1/64"
            ];
          };
          "50-bridge101" = {
            matchConfig.Name = "bridge101";
            enable = true;
            address = [
              "10.0.136.1/21"
              "2001:470:f026:101::1/64"
            ];
          };
          "50-bridge102" = {
            matchConfig.Name = "bridge102";
            enable = true;
            address = [
              "10.0.2.1/24"
              "2001:470:f026:102::1/64"
            ];
          };
          "50-bridge103" = {
            matchConfig.Name = "bridge103";
            enable = true;
            address = [
              "10.0.3.1/24"
              "2001:470:f026:103::1/64"
            ];
          };
          "50-bridge104" = {
            matchConfig.Name = "bridge104";
            enable = true;
            networkConfig.DHCP = false;
            address = [
              "172.20.4.3/24"
              "2001:470:f026:104::3/64"
            ];
            routes = [
              { Gateway = "172.20.4.1"; }
            ];
          };
          "50-bridge105" = {
            matchConfig.Name = "bridge105";
            enable = true;
            address = [
              "10.0.5.1/24"
              "2001:470:f026:105::1/64"
            ];
          };
          "50-bridge107" = {
            matchConfig.Name = "bridge107";
            enable = true;
            address = [
              "2001:470:f026:107::1/64"
            ];
          };
          "50-bridge110" = {
            matchConfig.Name = "bridge110";
            enable = true;
            address = [
              "10.0.10.1/24"
              "2001:470:f026:110::1/64"
            ];
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
      services.frr.router-id = "172.20.4.3";
      services.frr.broadcast-interface = [
        "bridge104" # border
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
            "2001:470:f026:107::1%%bridge107"
            "2001:470:f026:110::1%%bridge110"
          ];
          upstreamInterfaces = [ "2001:470:f026:103::20%%bridge103" ];
        };
      };
    };
  };
}
