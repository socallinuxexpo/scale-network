{
  config,
  lib,
  ...
}:
let
  cfg = config.scale-network.services.frr;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.services.frr.enable = mkEnableOption "SCaLE network FRR daemon";

  config = mkIf cfg.enable {
    services.frr = {

      ospfd.enable = true;
      ospfd.options = [
        "-A 127.0.0.1 -M snmp"
      ];

      config = ''
        interface eth1
         ip address 10.1.1.2/24
         ip ospf priority 0
        exit
        !
        interface eth2
         ip address 10.1.3.2/24
         ip ospf priority 0
        exit
        !
        router ospf
         network 10.1.1.0/24 area 0
        exit
        !
      '';

    };
  };
}
