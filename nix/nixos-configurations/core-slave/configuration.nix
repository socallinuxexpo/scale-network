{
  config,
  lib,
  pkgs,
  ...
}:

{
  scale-network.facts = {
    ipv4 = "10.0.3.5/24";
    ipv6 = "2001:470:f026:103::5/64";
    eth = "eth0";
  };
  # For now the master/slave kea configs are the same
  scale-network.services.keaMaster.enable = true;
  scale-network.services.bindSlave = {
    enable = true;
    masters = [ "2001:470:f026:503::20" ];
  };
  scale-network.services.ntp.enable = true;

  networking.hostName = "coreslave";

  networking = {
    extraHosts = ''
      10.0.3.5 coreexpo.scale.lan
    '';
  };

  # Make sure that the makes of these files are actually lexicographically before 99-default.link provides by systemd defaults since first match wins
  # Ref: https://github.com/systemd/systemd/issues/9227#issuecomment-395500679
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks = {
      "10-lan" = {
        name = "e*0";
        enable = true;
        address = [
          config.scale-network.facts.ipv4
          config.scale-network.facts.ipv6
        ];
        routes = [
          { routeConfig.Gateway = "10.0.3.1"; }
          { routeConfig.Gateway = "2001:470:f026:103::1"; }
        ];
      };
    };
  };
}
