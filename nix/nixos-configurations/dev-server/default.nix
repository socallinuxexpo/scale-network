{
  release = "unstable";

  modules =
    {
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        ./disko.nix
        ./hardware-configuration.nix
      ];

      config = {
        nixpkgs.hostPlatform = "x86_64-linux";

        scale-network = {
          base.enable = true;
          libvirt.enable = true;
          services.gitlab.enable = true;
          services.bindMaster.enable = true;
          services.keaMaster.enable = true;
          services.prometheus.enable = false;
          services.ssh.enable = false;
          timeServers.enable = false;

          users.berkhan.enable = true;
          users.dlang.enable = true;
          users.jsh.enable = true;
          users.kylerisse.enable = true;
          users.owen.enable = true;
          users.rhamel.enable = true;
          users.rob.enable = true;
          users.root.enable = true;
          users.ruebenramirez.enable = true;
        };

        nix.extraOptions = ''
          experimental-features = nix-command flakes
        '';

        networking = {
          useNetworkd = true;
          useDHCP = false;
          firewall.enable = true;
        };

        # ensure non-mgmt interfaces disable accept RA for ipv6
        # opting for sysctl and IPv6AcceptRA=false for systemd.networkd
        boot.kernel.sysctl = {
          "net.ipv6.conf.bridge100.autoconf" = false;
          "net.ipv6.conf.bridge101.autoconf" = false;
          "net.ipv6.conf.bridge102.autoconf" = false;
          "net.ipv6.conf.bridge104.autoconf" = false;
          "net.ipv6.conf.bridge105.autoconf" = false;
          "net.ipv6.conf.bridge107.autoconf" = false;
          "net.ipv6.conf.bridge110.autoconf" = false;
          "net.ipv6.conf.bridge112.autoconf" = false;
          "net.ipv6.conf.bridge499.autoconf" = false;
          # completely disable IPv6 temporary addresses
          "net.ipv6.conf.default.use_tempaddr" = lib.mkForce 0;
        };

        systemd.network = {
          # The notion of "online" is a broken concept
          # https://github.com/systemd/systemd/blob/e1b45a756f71deac8c1aa9a008bd0dab47f64777/NEWS#L13
          # https://github.com/NixOS/nixpkgs/issues/247608
          wait-online.enable = false;
          enable = true;
          netdevs = {
            "10-bond0" = {
              netdevConfig = {
                Kind = "bond";
                Name = "bond0";
              };
              bondConfig = {
                Mode = "802.3ad";
                LACPTransmitRate = "fast";
                TransmitHashPolicy = "layer3+4";
              };
            };
            # servers -- Owen's 192.159.10.0/25 server VLAN
            "20-vlan10" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan10";
              };
              vlanConfig.Id = 10;
            };
            # exSCALE-SLOW
            "20-vlan100" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan100";
              };
              vlanConfig.Id = 100;
            };
            # exSCALE-FAST
            "20-vlan101" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan101";
              };
              vlanConfig.Id = 101;
            };
            # exSpeaker
            "20-vlan102" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan102";
              };
              vlanConfig.Id = 102;
            };
            # exInfra
            "20-vlan103" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan103";
              };
              vlanConfig.Id = 103;
            };
            # exMDF
            "20-vlan104" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan104";
              };
              vlanConfig.Id = 104;
            };
            # exAVLAN
            "20-vlan105" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan105";
              };
              vlanConfig.Id = 105;
            };
            # exSigns
            "20-vlan107" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan107";
              };
              vlanConfig.Id = 107;
            };
            # exRegistration
            "20-vlan110" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan110";
              };
              vlanConfig.Id = 110;
            };
            # exVmVendor (Special VLAN for S.O.D.A. machine)
            "20-vlan112" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan112";
              };
              vlanConfig.Id = 112;
            };
            # Vendor Backbone (OSPF Backbone for Expo Switches carrying Vendor VLANs)
            "20-vlan499" = {
              netdevConfig = {
                Kind = "vlan";
                Name = "vlan499";
              };
              vlanConfig.Id = 499;
            };
            "25-bridge10" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge10";
              };
            };
            "25-bridge100" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge100";
              };
            };
            "25-bridge101" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge101";
              };
            };
            "25-bridge102" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge102";
              };
            };
            "25-bridge103" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge103";
              };
            };
            "25-bridge104" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge104";
              };
            };
            "25-bridge105" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge105";
              };
            };
            "25-bridge107" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge107";
              };
            };
            "25-bridge110" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge110";
              };
            };
            "25-bridge112" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge112";
              };
            };
            "25-bridge499" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "bridge499";
              };
            };
          };
          networks = {
            "20-eno1" = {
              matchConfig.Name = "eno1";
              networkConfig = {
                Bond = "bond0";
                LLDP = true;
                EmitLLDP = true;
              };
            };
            "20-eno2" = {
              matchConfig.Name = "eno2";
              networkConfig = {
                Bond = "bond0";
                LLDP = true;
                EmitLLDP = true;
              };
            };
            "20-eno3" = {
              matchConfig.Name = "eno3";
              networkConfig = {
                Bond = "bond0";
                LLDP = true;
                EmitLLDP = true;
              };
            };
            "20-eno4" = {
              matchConfig.Name = "eno4";
              networkConfig = {
                Bond = "bond0";
                LLDP = true;
                EmitLLDP = true;
              };
            };
            "30-bond0" = {
              matchConfig.Name = "bond0";
              linkConfig = {
                RequiredForOnline = "carrier";
              };
              networkConfig = {
                LinkLocalAddressing = "no";
              };
              # tag vlan on this link
              vlan = [
                "vlan10" # DC management vlan
                "vlan100"
                "vlan101"
                "vlan102"
                "vlan103"
                "vlan104"
                "vlan105"
                "vlan107"
                "vlan110"
                "vlan112"
                "vlan499"
              ];
            };
            "40-vlan10" = {
              matchConfig.Name = "vlan10";
              networkConfig = {
                Bridge = "bridge10";
              };
            };
            "40-vlan100" = {
              matchConfig.Name = "vlan100";
              networkConfig = {
                Bridge = "bridge100";
              };
            };
            "40-vlan101" = {
              matchConfig.Name = "vlan101";
              networkConfig = {
                Bridge = "bridge101";
              };
            };
            "40-vlan102" = {
              matchConfig.Name = "vlan102";
              networkConfig = {
                Bridge = "bridge102";
              };
            };
            "40-vlan103" = {
              matchConfig.Name = "vlan103";
              networkConfig = {
                Bridge = "bridge103";
              };
            };
            "40-vlan104" = {
              matchConfig.Name = "vlan104";
              networkConfig = {
                Bridge = "bridge104";
              };
            };
            "40-vlan105" = {
              matchConfig.Name = "vlan105";
              networkConfig = {
                Bridge = "bridge105";
              };
            };
            "40-vlan107" = {
              matchConfig.Name = "vlan107";
              networkConfig = {
                Bridge = "bridge107";
              };
            };
            "40-vlan110" = {
              matchConfig.Name = "vlan110";
              networkConfig = {
                Bridge = "bridge110";
              };
            };
            "40-vlan112" = {
              matchConfig.Name = "vlan112";
              networkConfig = {
                Bridge = "bridge112";
              };
            };
            "40-vlan499" = {
              matchConfig.Name = "vlan499";
              networkConfig = {
                Bridge = "bridge499";
              };
            };
            "50-bridge10" = {
              matchConfig.Name = "bridge10";
              enable = true;
              networkConfig = {
                DHCP = "yes";
              };
            };
            "50-bridge100" = {
              matchConfig.Name = "bridge100";
              enable = true;
              networkConfig = {
                IPv6AcceptRA = false;
              };
            };
            "50-bridge101" = {
              matchConfig.Name = "bridge101";
              enable = true;
              networkConfig = {
                IPv6AcceptRA = false;
              };
            };
            "50-bridge102" = {
              matchConfig.Name = "bridge102";
              enable = true;
              networkConfig = {
                IPv6AcceptRA = false;
              };
            };
            "50-bridge103" = {
              matchConfig.Name = "bridge103";
              enable = true;
              address = [
                "10.0.3.20/24"
                "2001:470:f026:103::20/64"
              ];
              routes = [
                {
                  Destination = "10.0.0.0/8";
                  Gateway = "10.0.3.1";
                  GatewayOnLink = true;
                }
                {
                  Destination = "2001:470:f026::/48";
                  Gateway = "2001:470:f026:103::1";
                  GatewayOnLink = true;
                }
              ];
            };
            "50-bridge104" = {
              matchConfig.Name = "bridge104";
              enable = true;
              networkConfig = {
                IPv6AcceptRA = false;
              };
            };
            "50-bridge105" = {
              matchConfig.Name = "bridge105";
              enable = true;
              networkConfig = {
                IPv6AcceptRA = false;
              };
            };
            "50-bridge107" = {
              matchConfig.Name = "bridge107";
              enable = true;
              networkConfig = {
                IPv6AcceptRA = false;
              };
            };
            "50-bridge110" = {
              matchConfig.Name = "bridge110";
              enable = true;
              networkConfig = {
                IPv6AcceptRA = false;
              };
            };
            "50-bridge112" = {
              matchConfig.Name = "bridge112";
              enable = true;
              networkConfig = {
                IPv6AcceptRA = false;
              };
            };
            "50-bridge499" = {
              matchConfig.Name = "bridge499";
              enable = true;
              networkConfig = {
                IPv6AcceptRA = false;
              };
            };
          };
        };

        # This are needed for kea to know which port to bind to
        scale-network.facts = {
          ipv4 = "10.0.3.20/24";
          ipv6 = "2001:470:f026:103::20/64";
          eth = "bridge103";
        };

        networking = {
          extraHosts = ''
            10.0.3.20 coreexpo.scale.lan
          '';
        };

        environment.systemPackages = with pkgs; [
          wget
          git
          vim
          efibootmgr
          gptfdisk
          screen
        ];

        services.openssh = {
          enable = true;
          openFirewall = true;
        };

      };
    };
}
