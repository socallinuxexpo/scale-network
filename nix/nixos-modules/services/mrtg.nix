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

  config = mkIf cfg.enable {
    systemd.services.mrtg-generator =
      let
        unfilteredList = (
          builtins.split "\n" (
            builtins.readFile "${pkgs.scale-network.scale-inventory}/config/all-network-devices"
          )
        );
        filteredList = (builtins.filter (line: line != [ ] && line != "") unfilteredList);
        script = pkgs.writeShellScript "" ''
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
      {
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

    users = {
      users."${cfg.user}" = {
        isNormalUser = true;
        group = "${cfg.group}";
      };
      groups.${cfg.group} = { };
    };
  };
}
