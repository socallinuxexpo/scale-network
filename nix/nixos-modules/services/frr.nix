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
         passive-interface default
         network 10.0.0.0/8 area 0
         redistribute connected
        exit
        router ospf6
         passive-interface default
         redistribute connected
        exit
      '';
    };

  };

  config = mkIf cfg.enable {

    services.frr = {

      ospfd.enable = true;
      ospfd.options = [
        "-A 127.0.0.1 -M snmp"
      ];

      config =
        let

          router-id-config = "router-id ${cfg.router-id}";

          broadcast-interface-config = concatStringsSep "\n" (
            map (x: ''
              interface ${x}
               no ip ospf passive
               ip ospf network broadcast
               ip ospf hello-interval 1
               ip ospf dead-interval 3
               no ipv6 ospf6 passive
               ipv6 ospf6 network broadcast
               ipv6 ospf6 hello-interval 1
               ipv6 ospf6 dead-interval 3
              exit
            '') cfg.broadcast-interface
          );

        in
        concatStringsSep "\n" [
          router-id-config
          broadcast-interface-config
          cfg.routing-config
        ];

    };
  };
}
