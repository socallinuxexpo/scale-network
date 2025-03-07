{
  config,
  pkgs,
  lib,
  ...
}:
let

  cfg = config.scale-network.services.mrtg;

  inherit (lib)
    types
    ;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    mkOption
    ;
in

{

  options.scale-network.services.mrtg = {

    enable = mkEnableOption "SCaLE mrtg monitoring service";

    user = mkOption {
      type = types.str;
      default = "mrtg";
    };

    group = mkOption {
      type = types.str;
      default = "mrtg";
    };

    statePath = mkOption {
      type = types.str;
      default = "/persist/var/lib/mrtg";
    };
  };

  config =
    let
      unfilteredList = (
        builtins.split "\n" (
          builtins.readFile "${pkgs.scale-network.scaleInventory}/config/all-network-devices"
        )
      );
      filteredList = (builtins.filter (line: line != [ ] && line != "") unfilteredList);
      script = pkgs.writeShellScript "mrtg-generator" ''
        set -x
        mkdir -p ${cfg.statePath}/configs
        mkdir -p ${cfg.statePath}/graphs
        for hostname in ${toString filteredList}; do
          echo "''${hostname}"
          ${pkgs.mrtg}/bin/cfgmaker \
          --enable-ipv6 \
          --no-down \
          --show-op-down \
          --output="${cfg.statePath}/configs/''${hostname}.cfg" \
          --global="WorkDir: ${cfg.statePath}/graphs/''${hostname}/" \
          Junitux@''${hostname}
        done
      '';
    in
    mkIf cfg.enable (lib.mkMerge [
      {
        systemd.services = builtins.listToAttrs (
          map (name: {
            name = "${name}-mrtg";
            value = {
              after = [ "mrtg-generator.service" ];
              environment.LANG = "C";
              serviceConfig = {
                ExecStart = "${pkgs.mrtg}/bin/mrtg ${cfg.statePath}/configs/${name}.cfg";
                User = "${cfg.user}";
                Group = "${cfg.group}";
                Type = "simple";
              };
            };
          }) filteredList
        );
        systemd.timers = builtins.listToAttrs (
          map (name: {
            name = "${name}-mrtg";
            value = {
              wantedBy = [ "timers.target" ];
              timerConfig = {
                OnBootSec = "5m";
                OnUnitActiveSec = "5m";
                RandomizedDelaySec = "30";
                Unit = "${name}-mrtg.service";
              };
            };
          }) filteredList
        );
      }
      {
        systemd.services.mrtg-generator = {
          description = "mrtg generator";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            User = "${cfg.user}";
            Group = "${cfg.group}";
            ExecStart = "${script}";
            Type = "simple";
          };
        };
        systemd.tmpfiles.rules = [
          "d ${cfg.statePath} 0755 ${cfg.user} ${cfg.group}"
        ];

        #mrtg ${cfg.statePath}/configs/${hostname}

        users = {
          users."${cfg.user}" = {
            isNormalUser = true;
            group = "${cfg.group}";
          };
          groups.${cfg.group} = { };
        };
      }
    ]);
}
