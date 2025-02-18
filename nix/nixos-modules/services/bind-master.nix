{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.scale-network.services.bindMaster;
  cfgBind = config.services.bind;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.types)
    listOf
    str
    ;

  inherit (lib.options)
    mkEnableOption
    ;
  zoneSerial = toString inputs.self.lastModified;
in
{
  options.scale-network.services.bindMaster = {
    enable = mkEnableOption "SCaLE network Bind master server";

    slaves = lib.mkOption {
      type = listOf str;
      default = [ ];
      description = ''
        List bind slave server addresses.
      '';
    };
  };

  config = mkIf cfg.enable {
    networking = {
      #useDHCP = false;
      firewall.allowedTCPPorts = [
        53
      ];
      firewall.allowedUDPPorts = [
        53
      ];
    };

    environment.systemPackages = with pkgs; [
      ldns
      bind
    ];

    environment.etc."bind/named.conf".source = config.services.bind.configFile;

    systemd.services.bind = {
      serviceConfig.ExecStart = lib.mkForce "${cfgBind.package.out}/sbin/named -u named ${lib.strings.optionalString cfgBind.ipv4Only "-4"} -c /etc/bind/named.conf -f";
      restartTriggers = [
        cfgBind.configFile
      ];
    };

    services = {
      # TODO: This should be disable but was enabled in core originally
      resolved.enable = false;
      bind = {
        enable = true;
        cacheNetworks = [
          "::1/128"
          "127.0.0.0/8"
          "2001:470:f026::/48"
          "10.0.0.0/8"
        ];
        forwarders = [
          "8.8.8.8"
          "8.8.4.4"
        ];
        zones = {
          "scale.lan." = {
            master = true;
            slaves = cfg.slaves;
            file = pkgs.writeText "named.scale.lan" (
              lib.strings.concatStrings [
                ''
                  $ORIGIN scale.lan.
                  $TTL    86400
                  @ IN SOA coreexpo.scale.lan. admin.scale.lan. (
                  ${zoneSerial}           ; serial number
                  3600                    ; refresh
                  900                     ; retry
                  1209600                 ; expire
                  1800                    ; ttl
                  )
                                  IN    NS      coreexpo.scale.lan.
                                  IN    NS      coreconf.scale.lan.
                ''
                (builtins.readFile "${pkgs.scale-network.scaleInventory}/config/db.scale.lan.records")
              ]
            );
          };
          "10.in-addr.arpa." = {
            master = true;
            slaves = cfg.slaves;
            file = pkgs.writeText "named-10.rev" (
              lib.strings.concatStrings [
                ''
                  $ORIGIN 10.in-addr.arpa.
                  $TTL    86400
                  10.in-addr.arpa. IN SOA coreexpo.scale.lan. admin.scale.lan. (
                  ${zoneSerial}           ; serial number
                  3600                    ; refresh
                  900                     ; retry
                  1209600                 ; expire
                  1800                    ; ttl
                  )
                                  IN NS      coreexpo.scale.lan.
                                  IN NS      coreconf.scale.lan.
                ''
                (builtins.readFile "${pkgs.scale-network.scaleInventory}/config/db.ipv4.arpa.records")
              ]
            );
          };
          # 2001:470:f026::
          "6.2.0.f.0.7.4.0.1.0.0.2.ip6.arpa." = {
            master = true;
            slaves = cfg.slaves;
            file = pkgs.writeText "named-2001.470.f026-48.rev" (
              lib.strings.concatStrings [
                ''
                  $ORIGIN 6.2.0.f.0.7.4.0.1.0.0.2.ip6.arpa.
                  $TTL    86400
                  @ IN SOA coreexpo.scale.lan. admin.scale.lan. (
                  ${zoneSerial}           ; serial number
                  3600                    ; refresh
                  900                     ; retry
                  1209600                 ; expire
                  1800                    ; ttl
                  )
                                  IN NS      coreexpo.scale.lan.
                                  IN NS      coreconf.scale.lan.
                ''
                (builtins.readFile "${pkgs.scale-network.scaleInventory}/config/db.ipv6.arpa.records")
              ]
            );
          };
        };
      };
    };
  };
}
