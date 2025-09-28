{
  config,
  lib,
  ...
}:

let
  cfg = config.scale-network.router.conference;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.router.conference.enable =
    mkEnableOption "SCaLE network conference router setup";

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
        "10.1.1.2/24"
      ];
    };
    # Physical link to expo
    systemd.network.networks."10-expo" = {
      matchConfig.Name = "eth2";
      networkConfig.DHCP = false;
      address = [
        "10.1.3.2/24"
      ];
    };
  };
}
