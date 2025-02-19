{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.scale-network.services.bindSlave;

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
in
{
  options.scale-network.services.bindSlave = {
    enable = mkEnableOption "SCaLE network Bind master server";

    masters = lib.mkOption {
      type = listOf str;
      description = ''
        List bind master server addresses.
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

    systemd.services.bind =
      let
        # Get original config
        cfg = config.services.bind;
      in
      {
        serviceConfig.ExecStart = lib.mkForce "${cfg.package.out}/sbin/named -u named ${lib.strings.optionalString cfg.ipv4Only "-4"} -c /etc/bind/named.conf -f";
        restartTriggers = [
          cfg.configFile
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
        extraOptions = ''
          transfer-source-v6 ${builtins.head (lib.splitString "/" config.scale-network.facts.ipv6)};
        '';
        zones = {
          "scale.lan." = {
            master = false;
            masters = cfg.masters;
            file = "/var/run/named/sec-scale.lan";
          };
          "10.in-addr.arpa." = {
            master = false;
            masters = cfg.masters;
            file = "/var/run/named/sec-10.rev";
          };
          # 2001:470:f026::
          "6.2.0.f.0.7.4.0.1.0.0.2.ip6.arpa." = {
            master = false;
            masters = cfg.masters;
            file = "/var/run/named/sec-2001.470.f026-48.rev";
          };
        };
      };
    };
  };
}
