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

        # make friend eth names based on paths from lspci -D
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

        systemd.network = {
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
              dhcpV4Config = {
                UseGateway = false;
                UseRoutes = false;
              };
              linkConfig.RequiredForOnline = "no";
            };
          };
        };
      };
    };
}
