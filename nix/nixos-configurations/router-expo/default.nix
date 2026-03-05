{
  release = "unstable";

  modules =
    { lib, ... }:
    let
      inherit (lib)
        const
        mapAttrs
        recursiveUpdate
        ;
    in
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

        systemd.network = {
          # make friend eth names based on paths from lspci -D
          links =
            mapAttrs
              (const (recursiveUpdate {
                linkConfig.AlternativeNamesPolicy = [
                  "database"
                  "onboard"
                  "slot"
                  "path"
                  "mac"
                ];
              }))
              {
                # Ethernet controller: Realtek Semiconductor Co., Ltd. RTL8111/8168/8211/8411 PCI Express Gigabit Ethernet Controller (rev 15)
                "10-backdoor0" = {
                  matchConfig.Path = "pci-0000:11:00.0";
                  linkConfig.Name = "backdoor0";
                };
                # Ethernet controller: Intel Corporation I350 Gigabit Network Connection (rev 01)
                "10-copper0" = {
                  matchConfig.Path = "pci-0000:0d:00.0";
                  linkConfig = {
                    Name = "copper0";
                    AlternativeName = "TRexpoIDF";
                  };
                };
                "10-copper1" = {
                  matchConfig.Path = "pci-0000:0d:00.1";
                  linkConfig = {
                    Name = "copper1";
                    AlternativeName = "TRCatwalk";
                  };
                };
                "10-copper2" = {
                  matchConfig.Path = "pci-0000:0d:00.2";
                  linkConfig = {
                    Name = "copper2";
                    AlternativeName = "TechServer";
                  };
                };
                "10-copper3" = {
                  matchConfig.Path = "pci-0000:0d:00.3";
                  linkConfig = {
                    Name = "copper3";
                    AlternativeName = "AVServer";
                  };
                };
                # Ethernet controller: Intel Corporation 82599ES 10-Gigabit SFI/SFP+ Network Connection (rev 01)
                "10-fiber0" = {
                  matchConfig.Path = "pci-0000:03:00.0";
                  linkConfig = {
                    Name = "fiber0";
                    AlternativeName = "toborder0";
                  };
                };
                "10-fiber1" = {
                  matchConfig.Path = "pci-0000:03:00.1";
                  linkConfig = {
                    Name = "fiber1";
                    AlternativeName = "toconf0";
                  };
                };
                "10-fiber2" = {
                  matchConfig.Path = "pci-0000:06:00.0";
                  linkConfig = {
                    Name = "fiber2";
                    AlternativeName = "TRneidf0";
                  };
                };
                "10-fiber3" = {
                  matchConfig.Path = "pci-0000:06:00.1";
                  linkConfig = {
                    Name = "fiber3";
                    AlternativeName = "TRnwidf0";
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
                IPv6AcceptRA = true;
              };
              dhcpV4Config = {
                UseGateway = false;
                UseRoutes = false;
              };
              ipv6AcceptRAConfig = {
                UseGateway = false;
              };
              linkConfig.RequiredForOnline = "no";
            };
          };
        };
      };
    };
}
