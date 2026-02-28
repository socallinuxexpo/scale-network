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

      netdevs = {
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
      };
      networks = mkMerge [
        {
          # Physical link to conference center
          "30-${cfg.frrConferenceInterface}" = {
            matchConfig.Name = cfg.frrConferenceInterface;
            networkConfig = {
              LinkLocalAddressing = "no";
              LLDP = true;
              EmitLLDP = true;
            };
            vlan = [
              "vlan901"
            ];
          };
          "30-${cfg.frrExpoInterface}" = {
            matchConfig.Name = cfg.frrExpoInterface;
            networkConfig = {
              LinkLocalAddressing = "no";
              LLDP = true;
              EmitLLDP = true;
            };
            vlan = [
              "vlan103"
              "vlan104"
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
              "10.0.3.2/24"
              "2001:470:f026:103::2/64"
            ];
          };
          "40-vlan901" = {
            matchConfig.Name = "vlan901";
            networkConfig = {
              Bridge = "bridge901";
            };
          };
          "40-vlan104" = {
            matchConfig.Name = "vlan104";
            networkConfig = {
              Bridge = "bridge104";
            };
          };
          "50-bridge901" = {
            matchConfig.Name = "bridge901";
            networkConfig.DHCP = false;
            address = [
              "172.20.1.1/24"
              "2001:470:f026:901::1/64"
            ];
          };
          "50-bridge104" = {
            matchConfig.Name = "bridge104";
            networkConfig.DHCP = false;
            address = [
              "172.20.4.1/24"
              "2001:470:f026:104::1/64"
            ];
          };
        }
        (mkIf (!cfg.staticWANEnable) {
          # temporary for testing at various sites
          # will be static for show
          "10-${cfg.WANInterface}" = {
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
          "10-${cfg.WANInterface}" = {
            matchConfig.Name = cfg.WANInterface;
            networkConfig = {
              DHCP = false;
              LLDP = true;
              EmitLLDP = true;
            };
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
      services.frr.router-id = "172.20.1.1";
      services.frr.broadcast-interface = [
        "bridge104" # expo
        "bridge901" # cf
      ];
      # service.frr.passive-interface add 103 and 104 later
    };
  };
}
