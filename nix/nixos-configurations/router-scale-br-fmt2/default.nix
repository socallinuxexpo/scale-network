{
  release = "unstable";

  modules =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [
        ./configuration.nix
        ./hardware-configuration.nix
        ./disko.nix
      ];

      config = {

        # verify: modinfo -p ixgbe
        boot.extraModprobeConfig = ''
          options ixgbe allow_unsupported_sfp=1,1
        '';
        boot.kernelParams = [ "ixgbe" ];

        nixpkgs.hostPlatform = "x86_64-linux";
        # make friend eth names based on paths from lspci
        services.udev.extraRules = ''
          # Ethernet controller: Realtek Semiconductor Co., Ltd. RTL8111/8168/8211/8411 PCI Express Gigabit Ethernet Controller (rev 15)
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:0e:00.0", NAME="backdoor0"
          # Ethernet controller: Intel Corporation 82599ES 10-Gigabit SFI/SFP+ Network Connection (rev 01)
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:03:00.0", NAME="sfp0"
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:03:00.1", NAME="sfp1"
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:05:00.0", NAME="sfp2"
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:05:00.1", NAME="sfp3"
          # Ethernet controller: Intel Corporation I350 Gigabit Network Connection (rev 01)
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:08:00.0", NAME="copper0"
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:08:00.1", NAME="copper1"
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:08:00.2", NAME="copper2"
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:08:00.3", NAME="copper3"
        '';
        systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";

        boot.kernel.sysctl = {
          "net.ipv4.conf.all.forwarding" = true;
          "net.ipv6.conf.all.forwarding" = true;
        };

        networking.firewall.enable = false;
        networking.nftables.enable = true;
       ##FIXME## Add input, output, forward filters to match previous router config
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
              oifname "copper0" ip daddr 0.0.0.0/0 counter masquerade
            }
          }
        '';

        # must be disabled if using systemd.network
        networking.useDHCP = false;

        systemd.network = {
          enable = true;
          netdevs = {
            # HE Tunnel
            "20-hetunnel" = {
              netdevConfig = {
                Name = "he-tunnel";
                Kind = "sit";
                MTUBytes = 1480;
              };
              tunnelConfig = {
                Local = "192.159.10.47";
                Remote = "66.220.18.42";
              };
            };
            # 100 (SCALE-SLOW)
            "20-vlan100" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan100";
              };
            };
            "25-bridge100" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge100";
              };
            };
            # 101 (SCALE-FAST)
            "20-vlan101" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan101";
              };
            };
            "25-bridge101" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge101";
              };
            };
            # 102 (SCALE-Speaker)
            "20-vlan102" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan102";
              };
            };
            "25-bridge102" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge102";
              };
            };
            # expoInfra
            "20-vlan103" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan103";
              };
              vlanConfig.Id = 103;
            };
            "25-bridge103" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge103";
              };
            };
            # 104 (SCALE-Speaker)
            "20-vlan104" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan104";
              };
            };
            "25-bridge104" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge104";
              };
            };
            # 105 (SCALE-Speaker)
            "20-vlan105" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan105";
              };
            };
            "25-bridge105" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge105";
              };
            };
            # 107 (SCALE-Speaker)
            "20-vlan107" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan107";
              };
            };
            "25-bridge107" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge107";
              };
            };
            # 110 (SCALE-Speaker)
            "20-vlan110" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan110";
              };
            };
            "25-bridge110" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge110";
              };
            };
          };
          networks = {
            # Tunnel to HE Tunnelborker
            "30-hetunnel" = {
                matchConfig.Name = "he-tunnel";
                enable = true;
                networkConfig = {
                  DHCP = "no";
                  LLDP = false;
                  Address = [
                    "2001:470:c:3d::2/64"
                  ];
                  Gateway = "2001:470:c:3d::1";
                };
            };
            # Keep this for troubleshooting
            "30-backdoor" = {
              matchConfig.Name = "backdoor0";
              enable = true;
              networkConfig = {
                DHCP = "yes";
                LLDP = true;
                EmitLLDP = true;
              };
              networkConfig.IPv6AcceptRA = true;
              ipv6AcceptRAConfig = {
                UseGateway = false;
              };
              linkConfig.RequiredForOnline = "no";
            };
            "30-copper0" = {
              matchConfig.Name = "copper0";
              networkConfig = {
                DHCP = "yes";
                LLDP = true;
                EmitLLDP = true;
                Tunnel = "he-tunnel";
              };
              networkConfig.IPv6AcceptRA = true;
              ipv6AcceptRAConfig = {
                UseGateway = false;
              };
            };
            "30-copper1" = {
              matchConfig.Name = "copper1";
              linkConfig = {
                RequiredForOnline = "carrier";
              };
              networkConfig = {
                LinkLocalAddressing = "no";
              };
              vlan = [
                "vlan103"
              ];
            };
            # ExScaleSlow
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
            # ExScaleFast
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
            # ExSpeaker
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
                "10.0.2.1/21"
                "2001:470:f026:102::1/64"
              ];
            };
            # ExInfra
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
            # ExMDF
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
                "10.0.4.1/21"
                "2001:470:f026:104::1/64"
              ];
            };
            # ExAVLAN
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
                "10.0.5.1/21"
                "2001:470:f026:105::1/64"
              ];
            };
            # ExSigns
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
                "10.0.7.1/21"
                "2001:470:f026:107::1/64"
              ];
            };
            # ExRegistration
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
                "10.0.10.1/21"
                "2001:470:f026:110::1/64"
              ];
            };
            # vendor_backbone
            "40-vlan499" = {
              matchConfig.Name = "vlan499";
              networkConfig = {
                Bridge = "bridge499";
              };
            };
            "50-bridge499" = {
              matchConfig.Name = "bridge499";
              enable = true;
              address = [
                "10.1.0.1/24"
                "2001:470:f026:499::1/64"
              ];
            };
          };
        };
      };
    };
}
