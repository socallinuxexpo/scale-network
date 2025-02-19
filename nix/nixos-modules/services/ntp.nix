{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.scale-network.services.ntp;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.services.ntp.enable = mkEnableOption "SCaLE network ntp service";

  config = mkIf cfg.enable {
    services.ntp = {
      enable = true;
      # Default to time servers that are not Scales since we have to get time from somewhere
      servers = options.networking.timeServers.default;
      extraConfig = ''
        # Hosts on the local network(s) are not permitted because of the "restrict default"
        restrict 10.0.0.0/8 kod nomodify notrap nopeer
        restrict 2001:470:f026::/48 kod nomodify notrap nopeer
      '';
    };
  };
}
