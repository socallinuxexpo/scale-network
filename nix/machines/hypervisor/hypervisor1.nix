{ config, pkgs, lib, ... }:
{

  # ZFS uniq system ID
  # to generate: head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "25c531dc";

  networking = {
    # use systemd.networkd
    useNetworkd = true;
    useDHCP = false;
    firewall.enable = true;
  };

  systemd.network = {
    enable = true;
    netdevs.virbr0.netdevConfig = {
      Kind = "bridge";
      Name = "virbr0";
    };

    networks = {
      "1-virbr0" = {
        matchConfig.Name = "virbr0";
        enable = true;
        address = [ "10.128.3.20/24" "2001:470:f026:503::20/64" ];
        routes = [
          { routeConfig.Gateway = "10.128.3.1"; }
          { routeConfig.Gateway = "2001:470:f026:503::1"; }
        ];
      };
      "20-microvm-eth0" = {
        matchConfig.Name = "vm-*";
        networkConfig.Bridge = "virbr0";
      };
      "10-lan-eno2" = {
        matchConfig.Name = "eno2";
        networkConfig.Bridge = "virbr0";
        networkConfig = {
          LLDP = true;
          EmitLLDP = true;
        };
      };
      "10-lan-eno3" = {
        matchConfig.Name = "eno3";
        networkConfig.Bridge = "virbr0";
      };
      # Keep this for troubleshooting
      "10-lan" = {
        matchConfig.Name = "eno1";
        enable = true;
        networkConfig.DHCP = "yes";
      };
    };
  };

  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    tio
  ];

  microvm.autostart = [
    "coreMaster"
    "monitor"
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;
  };
}
