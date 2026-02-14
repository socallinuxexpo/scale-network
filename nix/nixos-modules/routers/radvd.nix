{
  config,
  lib,
  ...
}:

let
  cfg = config.scale-network.router.radvd;

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
  options.scale-network.router.radvd = {
    enable = mkEnableOption "SCaLE network router advertisements";
    vlans = mkOption {
      type = types.listOf types.str;
      description = ''
        VLANs list to advertise IPv6 prefixes
      '';
    };
  };

  config = mkIf cfg.enable {
    services.radvd = {
      enable = true;
      config = lib.concatMapStrings (vlan: ''
        interface bridge${vlan} {
          AdvSendAdvert on;
          # M Flag
          AdvManagedFlag on;
          # O Flag
          AdvOtherConfigFlag on;
          prefix 2001:470:f026:${vlan}::/64 {
            AdvOnLink on;
          };
        };
      '') cfg.vlans;
    };
  };

}
