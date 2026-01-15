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

  inherit (lib)
    types
    ;

  inherit (lib.options)
    mkEnableOption
    mkOption
    ;
in
{

  options.scale-network.router.conference = {
    enable = mkEnableOption "SCaLE network conference router setup";
    frrBorderInterface = mkOption {
      type = types.str;
      default = "fiber0";
      description = ''
        FRR broadcast interface to border
      '';
    };
    frrExpoInterface = mkOption {
      type = types.str;
      default = "fiber1";
      description = ''
        FRR broadcast interface to expo
      '';
    };
  };

  config = mkIf cfg.enable {
    networking.useNetworkd = true;
    systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";

    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

    # must be disabled if using systemd.network
    networking.useDHCP = false;

    systemd.network = {
      enable = true;
      # Physical link to border
      networks = {
        "10-border" = {
          matchConfig.Name = cfg.frrBorderInterface;
          networkConfig.DHCP = false;
          address = [
            "10.1.1.2/24"
          ];
        };
        # Physical link to expo
        "10-expo" = {
          matchConfig.Name = cfg.frrExpoInterface;
          networkConfig.DHCP = false;
          address = [
            "10.1.3.2/24"
          ];
        };
      };
    };

    networking.firewall.enable = false;

    scale-network = {
      services.frr.enable = true;
      services.frr.router-id = "10.1.1.2";
      services.frr.broadcast-interface = [
        cfg.frrBorderInterface
        cfg.frrExpoInterface
      ];
    };
  };
}
