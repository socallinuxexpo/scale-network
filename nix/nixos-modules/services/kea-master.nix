{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.scale-network.services.keaMaster;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.services.keaMaster.enable =
    mkEnableOption "SCaLE network kea master DHCP server";

  config = mkIf cfg.enable {
    networking = {
      firewall.allowedTCPPorts = [
        67
        68
      ];
      firewall.allowedUDPPorts = [
        67
        68
        547 # dhcpv6
      ];
    };

    environment.systemPackages = with pkgs; [
      kea
    ];

    # testing omitting basic auth
    systemd.services.kea-dhcp4-server.serviceConfig.ExecStart = lib.mkForce
      "${config.services.kea.package}/bin/kea-dhcp4 -X -c /etc/kea/dhcp4-server.conf";

    systemd.services.kea-dhcp6.serviceConfig.ExecStart = lib.mkForce
      "${config.services.kea.package}/bin/kea-dhcp6 -X -c /etc/kea/dhcp6-server.conf";

    services = {
      kea = {
        dhcp4 =
          let
            dhcp4PopulateConfig = pkgs.runCommand "replace" { } ''
              mkdir $out
              cp ${pkgs.scale-network.scale-inventory}/config/dhcp4-server.conf $TMP/dhcp4-server.conf
              substituteInPlace "$TMP/dhcp4-server.conf" \
                --replace-fail '@@INTERFACE@@' '${config.scale-network.facts.eth}'
              cp $TMP/dhcp4-server.conf $out
            '';
          in
          {
            enable = true;
            configFile = "${dhcp4PopulateConfig}/dhcp4-server.conf";
          };
        dhcp6 =
          let
            dhcp6PopulateConfig = pkgs.runCommand "replace" { } ''
              mkdir $out
              cp ${pkgs.scale-network.scale-inventory}/config/dhcp6-server-${config.scale-network.facts.building}.conf $TMP/dhcp6-server.conf
              substituteInPlace "$TMP/dhcp6-server.conf" \
                --replace-fail '@@SERVERADDRESS@@' '${builtins.head (lib.splitString "/" config.scale-network.facts.ipv6)}' \
                --replace-fail '@@INTERFACE@@' '${config.scale-network.facts.eth}'
              cp $TMP/dhcp6-server.conf $out
            '';
          in
          {
            enable = true;
            configFile = "${dhcp6PopulateConfig}/dhcp6-server.conf";
          };
      };
    };
  };
}
