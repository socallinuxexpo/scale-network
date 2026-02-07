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
          };
          networks = {
            # Keep this for troubleshooting
            "10-backdoor" = {
              matchConfig.Name = "backdoor0";
              enable = true;
              networkConfig = {
                DHCP = "yes";
                LLDP = true;
                EmitLLDP = true;
              };
              linkConfig.RequiredForOnline = "no";
            };
            "10-copper0" = {
              matchConfig.Name = "copper0";
              networkConfig = {
                DHCP = "yes";
                LLDP = true;
                EmitLLDP = true;
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
          };
        };
      };
    };
}
