{
  config,
  pkgs,
  lib,
  ...
}:
let

  inherit (lib)
    types
    ;

  inherit (lib.strings)
    concatMapStringsSep
    ;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    mkOption
    ;

  inherit (lib.attrsets)
    filterAttrs
    mapAttrs'
    ;

  cfg = config.scale-network.services.dhcp6-relay;

  enabledRelays = filterAttrs (relayName: cfg: cfg.enable) cfg;

  relayOpts = {

    options = {
      enable = mkEnableOption "SCaLE dhcp6-relay monitoring service";

      downstreamInterfaces = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };

      upstreamInterfaces = mkOption {
        type = types.listOf types.str;
      };
    };
  };

in

{
  options.scale-network.services.dhcp6-relay = mkOption {
    type = types.attrsOf (types.submodule relayOpts);
    default = { };
    description = "Specification of one or more dhcp6-relays.";
  };

  config = mkIf (enabledRelays != { }) {

    environment.systemPackages = [ pkgs.scale-network.isc-dhcp ];

    systemd.services = mapAttrs' (relayName: relayCfg: {
      name = "dhcp6-relay-${relayName}";
      value = {
        description = "dhcp6-relay monitoring service for ${relayName}";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          ExecStart = "${pkgs.scale-network.isc-dhcp}/bin/dhcrelay -6 -d --no-pid ${
            concatMapStringsSep " " (x: "-l ${x}") relayCfg.downstreamInterfaces
          } ${concatMapStringsSep " " (x: "-u ${x}") relayCfg.upstreamInterfaces}";
          Type = "exec";
          Restart = "always";
          DynamicUser = true;
          AmbientCapabilities = [
            "CAP_NET_RAW" # to send ICMP messages
            "CAP_NET_BIND_SERVICE" # to bind on DHCP port (546,547)
          ];
        };
      };
    }) enabledRelays;

    networking = {
      firewall.allowedUDPPorts = [
        546
        547
      ];
    };
  };
}
