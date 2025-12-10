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

        boot.kernel.sysctl = {
          "net.ipv4.conf.all.forwarding" = true;
          "net.ipv6.conf.all.forwarding" = true;
        };

        # verify: modinfo -p ixgbe
        boot.extraModprobeConfig = ''
          options ixgbe allow_unsupported_sfp=1,1
        '';

        nixpkgs.hostPlatform = "x86_64-linux";
        # make friend eth names based on paths from lspci
        services.udev.extraRules = ''
          # Ethernet controller: Realtek Semiconductor Co., Ltd. RTL8111/8168/8211/8411 PCI Express Gigabit Ethernet Controller (rev 15)
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:11:00.0", NAME="backdoor0"
          # Ethernet controller: Intel Corporation 82599ES 10-Gigabit SFI/SFP+ Network Connection (rev 01)
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:03:00.0", NAME="fiber0"
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:03:00.1", NAME="fiber1"
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:06:00.0", NAME="fiber2"
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:06:00.1", NAME="fiber3"
          # Ethernet controller: Intel Corporation I350 Gigabit Network Connection (rev 01)
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:0d:00.0", NAME="copper0"
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:0d:00.1", NAME="copper1"
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:0d:00.2", NAME="copper2"
          SUBSYSTEM=="net", ACTION=="add", KERNELS=="0000:0d:00.3", NAME="copper3"
        '';

        networking.firewall.enable = false;

        # must be disabled if using systemd.network
        networking.useDHCP = false;

        systemd.network = {
          enable = true;

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
            # Physical link to border
            "10-cf" = {
              matchConfig.Name = "fiber0";
              networkConfig.DHCP = false;
              address = [
                "10.1.1.2/24"
              ];
              linkConfig.RequiredForOnline = "routable";
              routes = [
                { Gateway = "10.1.1.1"; }
              ];
            };
            # Physical link to expo
            "10-expo" = {
              matchConfig.Name = "fiber1";
              networkConfig.DHCP = false;
              address = [
                "10.1.3.2/24"
              ];
            };
          };
        };
      };
    };
}
