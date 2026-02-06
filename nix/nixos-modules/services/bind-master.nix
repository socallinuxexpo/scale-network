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
  namedScaleLan = pkgs.writeText "named.scale.lan" (
    lib.strings.concatStrings [
      ''
        $ORIGIN scale.lan.
        $TTL    86400
        @ IN SOA core-slave.scale.lan. admin.scale.lan. (
        ${zoneSerial}           ; serial number
        3600                    ; refresh
        900                     ; retry
        1209600                 ; expire
        1800                    ; ttl
        )
                        IN    NS      core-slave.scale.lan.
                        IN    NS      core-master.scale.lan.
      ''
      (builtins.readFile "${pkgs.scale-network.scale-inventory}/config/db.scale.lan.records")
    ]
  );
  named10Rev = pkgs.writeText "named-10.rev" (
    lib.strings.concatStrings [
      ''
        $ORIGIN 10.in-addr.arpa.
        $TTL    86400
        10.in-addr.arpa. IN SOA core-slave.scale.lan. admin.scale.lan. (
        ${zoneSerial}           ; serial number
        3600                    ; refresh
        900                     ; retry
        1209600                 ; expire
        1800                    ; ttl
        )
                        IN NS      core-slave.scale.lan.
                        IN NS      core-master.scale.lan.
      ''
      (builtins.readFile "${pkgs.scale-network.scale-inventory}/config/db.ipv4.arpa.records")
    ]
  );
  named2001Rev = pkgs.writeText "named-2001.470.f026-48.rev" (
    lib.strings.concatStrings [
      ''
        $ORIGIN 6.2.0.f.0.7.4.0.1.0.0.2.ip6.arpa.
        $TTL    86400
        @ IN SOA core-slave.scale.lan. admin.scale.lan. (
        ${zoneSerial}           ; serial number
        3600                    ; refresh
        900                     ; retry
        1209600                 ; expire
        1800                    ; ttl
        )
                        IN NS      core-slave.scale.lan.
                        IN NS      core-master.scale.lan.
      ''
      (builtins.readFile "${pkgs.scale-network.scale-inventory}/config/db.ipv6.arpa.records")
    ]
  );
  namedConf = pkgs.writeText "named.conf" ''
    include "/etc/bind/rndc.key";
    controls {
      inet 127.0.0.1 allow {localhost;} keys {"rndc-key";};
    };

    acl cachenetworks {  ::1/128;  127.0.0.0/8;  2001:470:f026::/48;  10.0.0.0/8;  };
    acl badnetworks {  };

    options {
      listen-on {  any;  };
      listen-on-v6 {  any;  };
      allow-query { cachenetworks; };
      blackhole { badnetworks; };
      directory "/run/named";
      pid-file "/run/named/named.pid";
      allow-recursion { any; };
      resolver-query-timeout 3;
      dnssec-validation auto;
      max-cache-size 10%;
    };

    zone "." IN {
      type hint;
      file "${pkgs.dns-root-data}/root.hints";
    };


    zone "10.in-addr.arpa." {
      type master;
      file "${named10Rev}";
      allow-transfer { };
      allow-query { any; };
    };
    zone "6.2.0.f.0.7.4.0.1.0.0.2.ip6.arpa." {
      type master;
      file "${named2001Rev}";
      allow-transfer { };
      allow-query { any; };

    };
    zone "scale.lan." {
      type master;
      file "${namedScaleLan}";
      allow-transfer { };
      allow-query { any; };

    };

  '';
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

    systemd.services.bind = {
      restartTriggers = [
        cfgBind.configFile
      ];
    };

    services = {
      # TODO: This should be disable but was enabled in core originally
      resolved.enable = false;
      bind = {
        configFile = namedConf;
        enable = true;
      };
    };
  };
}
