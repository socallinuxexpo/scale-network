{
  config,
  lib,
  ...
}:
let
  cfg = config.scale-network.services.frr2;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.services.frr2.enable = mkEnableOption "SCaLE network FRR daemon";

  config = mkIf cfg.enable {

    services.frr = {

      ospfd.enable = true;
      ospfd.options = [
        "-A 127.0.0.1 -M snmp"
      ];

      config = ''
        router-id 10.1.1.1
        interface eth1
         ip address 10.1.1.1/24
         ip ospf network broadcast
         ip ospf hello-interval 1
         ip ospf dead-interval 3
        exit
        !
        interface eth2
         ip address 10.1.2.1/24
        exit
        !
        router ospf
         network 10.0.0.0/8 area 0
         redistribute connected
         timers throttle spf 50 100 5000
         timers lsa min-arrival 50
         timers throttle lsa all 50 100 5000
         fast-reroute enable
         fast-reroute keep-all-paths
        exit
        !
      '';

    };

    systemd.tmpfiles.rules = [
      "d /lib/frr 0700 frr frr -"
    ];

  };
}
