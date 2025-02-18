{
  config,
  ...
}:
{

  scale-network.facts = {
    ipv4 = "10.128.3.5/24";
    ipv6 = "2001:470:f026:503::5/64";
    eth = "eth0";
  };
  scale-network.services.keaMaster.enable = true;
  scale-network.services.bindMaster.enable = true;
  scale-network.services.ntp.enable = true;

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
        address = [
          config.scale-network.facts.ipv4
          config.scale-network.facts.ipv6
        ];
        routes = [
          { routeConfig.Gateway = "10.128.3.1"; }
          { routeConfig.Gateway = "2001:470:f026:503::1"; }
        ];
      };
    };
  };
}
