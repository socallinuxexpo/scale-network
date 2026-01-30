{ config, lib, ... }:

let
  cfg = config.scale-network.router.expo;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib)
    types
    ;

  inherit (lib.options)
    mkEnableOption
    mkOption
    ;
in
{

  options.scale-network.router.expo = {
    enable = mkEnableOption "SCaLE network expo router setup";
    frrBorderInterface = mkOption {
      type = types.str;
      default = "fiber0";
      description = ''
        FRR broadcast interface to border
      '';
    };
    frrConferenceInterface = mkOption {
      type = types.str;
      default = "fiber1";
      description = ''
        FRR broadcast interface to conference
      '';
    };
  };

  config = mkIf cfg.enable {
    networking = {
      useNetworkd = true;
      useDHCP = false;
      firewall.enable = true;
      nftables.enable = true;
    };

    systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";

    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

    systemd.network = {
      enable = true;
      networks = {
        # Physical link to border
        "10-border" = {
          matchConfig.Name = cfg.frrBorderInterface;
          networkConfig.DHCP = false;
          address = [
            "10.1.2.3/24"
          ];
        };
        # Physical link to conference
        "10-cf" = {
          matchConfig.Name = cfg.frrConferenceInterface;
          networkConfig.DHCP = false;
          address = [
            "10.1.3.3/24"
          ];
        };
      };
    };

    scale-network = {
      services.frr.enable = true;
      services.frr.router-id = "10.1.2.3";
      services.frr.broadcast-interface = [
        cfg.frrBorderInterface
        cfg.frrConferenceInterface
      ];
    };
  };
}
