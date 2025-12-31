{
  config,
  lib,
  ...
}:

let
  cfg = config.scale-network.router.border;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    mkOption
    ;

  inherit (lib)
    types
    mkMerge
    ;

in
{
  options.scale-network.router.border = {
    enable = mkEnableOption "SCaLE network border router setup";
    staticWANEnable = mkEnableOption "WAN Interface static IP";
    WANInterface = mkOption {
      type = types.str;
      default = "copper0";
      description = ''
        Internet goes here
      '';
    };
    frrConferenceInterface = mkOption {
      type = types.str;
      default = "fiber0";
      description = ''
        FRR interface to Conference
      '';
    };
    frrExpoInterface = mkOption {
      type = types.str;
      default = "fiber1";
      description = ''
        FRR interface to Expo
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

      networks = mkMerge [
        {
          netdevs = {
            "2-bridge900" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge900";
              };
            };
            "2-vlan900" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan900";
              };
              vlanConfig.Id = 900;
            };
            "2-bridge901" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge901";
              };
            };
            "2-vlan901" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan901";
              };
              vlanConfig.Id = 901;
            };
          };
          # Physical link to conference center
          systemd.network.networks."10-cf" = {
            matchConfig.Name = cfg.frrConferenceInterface;
            networkConfig = {
              Bridge = "bridge900";
            };
            vlan = [
              "vlan900"
            ];
          };
          # Physical link to expo
          systemd.network.networks."10-expo" = {
            matchConfig.Name = cfg.frrExpoInterface;
            networkConfig = {
              Bridge = "bridge901";
            };
            vlan = [
              "vlan901"
            ];
          };
          "50-bridge900" = {
            matchConfig.Name = "bridge900";
            networkConfig.DHCP = false;
            address = [
              "10.1.1.1/24"
            ];
          };
          "50-bridge901" = {
            matchConfig.Name = "bridge901";
            networkConfig.DHCP = false;
            address = [
              "10.1.2.1/24"
            ];
          };
        }
        (mkIf (!cfg.staticWANEnable) {
          # temporary for testing at various sites
          # will be static for show
          "10-nat-dhcp" = {
            matchConfig.Name = cfg.WANInterface;
            enable = true;
            networkConfig = {
              DHCP = "yes";
              LLDP = true;
              EmitLLDP = true;
            };
            linkConfig.RequiredForOnline = "no";
          };
        })

        (mkIf cfg.staticWANEnable {
          "10-nat-static" = {
            matchConfig.Name = cfg.WANInterface;
            networkConfig.DHCP = false;
            address = [
              "172.16.1.1/24"
            ];
          };
        })
      ];
    };

    networking.firewall.enable = false;
    networking.nftables.enable = true;
    networking.nftables.ruleset = ''
       table ip nat {
        chain PREROUTING {
          type nat hook prerouting priority dstnat; policy accept;
        }

        chain INPUT {
          type nat hook input priority 100; policy accept;
        }

        chain OUTPUT {
          type nat hook output priority -100; policy accept;
        }

        chain POSTROUTING {
          type nat hook postrouting priority srcnat; policy accept;
          oifname "${cfg.WANInterface}" ip daddr 0.0.0.0/0 counter masquerade
        }
      }
    '';
    scale-network = {
      services.frr.enable = true;
      services.frr.router-id = "10.1.1.1";
      services.frr.broadcast-interface = [
        "bridge900" # cf
        "bridge901" # expo
      ];
    };
  };
}
