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

  inherit (lib.lists)
    head
    tail
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
    broadcastInterfaces = mkOption {
      type = types.listOf types.str;
      default = [
        "fiber0"
        "fiber1"
      ];
      description = ''
        FRR interfaces
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
          # Physical link to conference center
          "10-cf" = {
            matchConfig.Name = head cfg.broadcastInterfaces;
            networkConfig.DHCP = false;
            address = [
              "10.1.1.1/24"
            ];
          };
          # Physical link to expo
          "10-expo" = {
            matchConfig.Name = tail cfg.broadcastInterfaces;
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
      services.frr.broadcast-interface = cfg.broadcastInterfaces;
    };

    system.stateVersion = "25.11";
  };
}
