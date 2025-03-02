{
  config,
  pkgs,
  lib,
  ...
}:
let

  cfg = config.scale-network.services.wasgeht;

  inherit (lib)
    types
    ;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    mkOption
    mkPackageOption
    ;

in

{

  options.scale-network.services.wasgeht = {

    enable = mkEnableOption "SCaLE wasgeht monitoring service";

    package = mkPackageOption pkgs.scale-network "wasgeht" { };

    hostFile = mkOption {
      type = types.str;
      default = "${pkgs.scale-network.scaleInventory}/scale-wasgeht-config.json";
    };

    logLevel = mkOption {
      type = types.str;
      default = "info";
    };

    port = mkOption {
      type = types.int;
      default = 1982;
    };

    statePath = mkOption {
      type = types.str;
      default = "/persist/var/lib/wasgeht";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.wasgeht = {
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} --data-dir=${cfg.statePath} --host-file=${cfg.hostFile} --port=${builtins.toString cfg.port} --log-level={cfg.logLevel}";
      };
      unitConfig = {
        ConditionPathExists = "!${cfg.statePath}";
      };
    };

  };
}
