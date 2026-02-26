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

    passive-interface = mkOption {
      description = "Passive Interface";
      type = types.listOf types.str;
      default = [ ];
    };

    routing-config = mkOption {
      description = "Routing Configuration";
      type = types.str;
      default = ''
        router ospf
         passive-interface default
         network 0.0.0.0/0 area 0
         redistribute connected
        exit
        router ospf6
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

      ospf6d.enable = true;
      ospf6d.options = [
        "-A ::1"
      ];

      config =
        let

          router-id-config = "router-id ${cfg.router-id}";

          broadcast-interface-config = concatStringsSep "\n" (
            map (x: ''
              interface ${x}
               no ip ospf passive
               ip ospf network broadcast
               ipv6 ospf6 network broadcast
               ipv6 ospf6 area 0
              exit
            '') cfg.broadcast-interface
          );

          passive-interface-config = concatStringsSep "\n" (
            map (x: ''
              interface ${x}
               ipv6 ospf6 passive
            '') cfg.passive-interface
          );

        in
        concatStringsSep "\n" [
          router-id-config
          broadcast-interface-config
          passive-interface-config
          cfg.routing-config
        ];

    };
  };
}
