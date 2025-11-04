{
  config,
  lib,
  ...
}:
let
  cfg = config.scale-network.services.frr;

  inherit (lib)
    types
    ;

  inherit (lib.lists)
    map
    ;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    mkOption
    ;

  inherit (lib.strings)
    concatStringsSep
    ;
in
{
  options.scale-network.services.frr = {
    enable = mkEnableOption "SCaLE network FRR daemon";

    router-id = mkOption {
      description = "FRR Router ID";
      type = types.str;
    };

    passive-interfaces = mkOption {
      description = "Passive OSPF Interfaces";
      type = types.listOf types.str;
      default = [ "eth0" ];
    };

    broadcast-interface = mkOption {
      description = "Broadcast Interface";
      type = types.listOf types.str;
      default = [ "eth1" ];
    };

    routing-config = mkOption {
      description = "Routing Configuration";
      type = types.str;
      default = ''
        router ospf
         network 10.0.0.0/8 area 0
         redistribute connected
         timers throttle spf 50 100 5000
         timers lsa min-arrival 50
         timers throttle lsa all 50 100 5000
         fast-reroute enable
         fast-reroute keep-all-paths
        exit
      '';
    };

  };

  config = mkIf cfg.enable {

    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

    services.frr = {

      ospfd.enable = true;
      ospfd.options = [
        "-A 127.0.0.1 -M snmp"
      ];

      config =
        let

          router-id-config = "router-id ${cfg.router-id}";

          passive-interfaces-config = concatStringsSep "\n" (
            map (x: ''
              interface ${x}
                ip ospf passive
              exit
            '') cfg.passive-interfaces
          );

          broadcast-interface-config = concatStringsSep "\n" (
            map (x: ''
              interface ${x}
               ip ospf network broadcast
               ip ospf hello-interval 1
               ip ospf dead-interval 3
              exit
            '') cfg.broadcast-interface
          );

        in
        concatStringsSep "\n" [
          router-id-config
          passive-interfaces-config
          broadcast-interface-config
          cfg.routing-config
        ];

    };
  };
}
