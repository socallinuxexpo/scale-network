{
  config,
  lib,
  ...
}:
let
  cfg = config.scale-network.timeServers;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.timeServers.enable = mkEnableOption "SCaLE network time servers setup";

  config = mkIf cfg.enable {
    # Sets the default timeservers for everything thats using the default: systemd-timesyncd
    networking.timeServers = [
      "ntpconf.scale.lan"
      "ntpexpo.scale.lan"
    ];
  };
}
