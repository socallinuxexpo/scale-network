{ config, lib, ... }:

let
  cfg = config.scale-network.router.expo;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{

  options.scale-network.router.expo.enable = mkEnableOption "SCaLE network expo router setup";

  config = mkIf cfg.enable {
    networking.useNetworkd = true;
    systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";

    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

    # Physical link to border
    systemd.network.networks."10-border" = {
      matchConfig.Name = "eth1";
      networkConfig.DHCP = false;
      address = [
        "10.1.2.3/24"
      ];
    };
    # Physical link to conference
    systemd.network.networks."10-cf" = {
      matchConfig.Name = "eth2";
      networkConfig.DHCP = false;
      address = [
        "10.1.3.3/24"
      ];
    };
  };
}
