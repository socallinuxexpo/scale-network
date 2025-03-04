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

    group = mkOption {
      type = types.str;
      default = "wasgehtd";
    };

    hostFile = mkOption {
      type = types.str;
      default = "${pkgs.scale-network.scaleInventory}/config/scale-wasgeht-config.json";
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

    user = mkOption {
      type = types.str;
      default = "wasgehtd";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.wasgeht = {
      description = "wasgeht monitoring service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "${cfg.user}";
        Group = "${cfg.group}";
        ExecStart = "${lib.getExe cfg.package} --data-dir=${cfg.statePath} --host-file=${cfg.hostFile} --port=${builtins.toString cfg.port} --log-level=${cfg.logLevel}";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR1 $MAINPID";
      };
    };
    systemd.tmpfiles.rules = [
      "d ${cfg.statePath} 0755 ${cfg.user} ${cfg.group}"
    ];
    users = {
      users."${cfg.user}" = {
        isNormalUser = true;
        group = "${cfg.group}";
      };
      groups.${cfg.group} = { };
    };
    networking = {
      firewall.allowedTCPPorts = [
        cfg.port
      ];
    };
  };
}
