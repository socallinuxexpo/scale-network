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
    ;
in
{
  options.scale-network.router.border.enable = mkEnableOption "SCaLE network border router setup";

  config = mkIf cfg.enable {
    networking.useNetworkd = true;
    systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";

    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

    # Physical link to Internet
    systemd.network.networks."10-inet" = {
      matchConfig.Name = "eth0";
      networkConfig.DHCP = true;
    };
    # Physical link to conference center
    systemd.network.networks."10-cf" = {
      matchConfig.Name = "eth1";
      networkConfig.DHCP = false;
      address = [
        "10.1.1.1/24"
      ];
    };
    # Physical link to expo hall
    systemd.network.networks."10-expo" = {
      matchConfig.Name = "eth2";
      networkConfig.DHCP = false;
      address = [
        "10.1.2.1/24"
      ];
    };
    # Physical link to cf Firewall
    systemd.network.networks."10-cffw" = {
      matchConfig.Name = "eth3";
      networkConfig.DHCP = false;
      address = [
        "172.16.1.1/24"
      ];
    };

    networking.nftables.ruleset = "";

    system.stateVersion = "25.11";
  };
}
