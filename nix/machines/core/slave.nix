{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./common.nix
    ];

  networking = {
    extraHosts = ''
      10.128.3.5 coreexpo.scale.lan
    '';
  };

  # Make sure that the makes of these files are actually lexicographically before 99-default.link provides by systemd defaults since first match wins
  # Ref: https://github.com/systemd/systemd/issues/9227#issuecomment-395500679
  systemd.network = {
    enable = true;
    networks = {
      "10-lan" = {
        name = "enp0*";
        enable = true;
        address = [ "10.128.3.5/24" "2001:470:f026:503::5/64" ];
        gateway = [ "10.128.3.1" ];
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
            master = false;
            masters = [ "2001:470:f026:103::5" ];
            file = "/var/named/sec-scale.lan";
          };
          "10.in-addr.arpa." = {
            master = false;
            masters = [ "2001:470:f026:103::5" ];
            file = "/var/named/sec-10.rev";
          };
          # 2001:470:f026::
          "6.2.0.f.0.7.4.0.1.0.0.2.ip6.arpa.." = {
            master = false;
            masters = [ "2001:470:f026:103::5" ];
            file = "/var/named/sec-2001.470.f026-48.rev";
          };
        };
    };
  };
}
