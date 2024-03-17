{ config, lib, pkgs, inputs, ... }:
let
  zoneSerial = toString inputs.self.lastModified;
in
{

  imports =
    [
      ./common.nix
    ];

  facts = {
    ipv4 = "10.128.3.5/24";
    ipv6 = "2001:470:f026:503::5/64";
    eth  = "eth0";
  };

  networking.hostName = "coremaster";

  # disable legacy networking bits as recommended by:
  #  https://github.com/NixOS/nixpkgs/issues/10001#issuecomment-905532069
  #  https://github.com/NixOS/nixpkgs/blob/82935bfed15d680aa66d9020d4fe5c4e8dc09123/nixos/tests/systemd-networkd-dhcpserver.nix
  networking = {
    extraHosts = ''
      10.128.3.5 coreconf.scale.lan
    '';
  };

  # Make sure that the nix/machines/core/master.nixmakes of these files are actually lexicographically before 99-default.link provides by systemd defaults since first match wins
  # Ref: https://github.com/systemd/systemd/issues/9227#issuecomment-395500679
  systemd.network = {
    enable = true;
    networks = {
      "10-lan" = {
        # to match enp0 or eth0
        name = "e*0*";
        enable = true;
        address = [ config.facts.ipv4 config.facts.ipv6 ];
        routes = [
          { routeConfig.Gateway = "10.128.3.1"; }
          { routeConfig.Gateway = "2001:470:f026:503::1"; }
        ];
      };
    };
  };

  services = {
    bind = {
      enable = true;
      cacheNetworks = [ "::1/128" "127.0.0.0/8" "2001:470:f026::/48" "10.0.0.0/8" ];
      forwarders = [ "8.8.8.8" "8.8.4.4" ];
      zones =
        {
          "scale.lan." = {
            master = true;
            slaves = [ "2001:470:f026:103::5" ];
            file = pkgs.writeText "named.scale.lan" (lib.strings.concatStrings [
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
              (builtins.readFile "${inputs.self.packages.${pkgs.system}.scaleInventory}/config/db.scale.lan.records")
            ]);
          };
          "10.in-addr.arpa." = {
            master = true;
            slaves = [ "2001:470:f026:103::5" ];
            file = pkgs.writeText "named-10.rev" (lib.strings.concatStrings [
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
              (builtins.readFile "${inputs.self.packages.${pkgs.system}.scaleInventory}/config/db.ipv4.arpa.records")
            ]);
          };
          # 2001:470:f026::
          "6.2.0.f.0.7.4.0.1.0.0.2.ip6.arpa." = {
            master = true;
            slaves = [ "2001:470:f026:103::5" ];
            file = pkgs.writeText "named-2001.470.f026-48.rev" (lib.strings.concatStrings [
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
              (builtins.readFile "${inputs.self.packages.${pkgs.system}.scaleInventory}/config/db.ipv6.arpa.records")
            ]);
          };
        };
    };
  };
}
