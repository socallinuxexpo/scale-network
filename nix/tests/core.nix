{
  name = "core";
  nodes = {
    coreServer = { lib, ... }: {
      imports = [ ../machines/core ];
    } // {
      virtualisation.vlans = [ 1 ];
      virtualisation.graphics = false;
      systemd.network = {
        networks = lib.mkForce {
          "01-eth1" = {
            name = "eth1";
            enable = true;
            address = [ "10.0.3.5/24" ];
            gateway = [ "10.0.3.1" ];
          };
        };
      };
    };

    client1 = { config, pkgs, ... }: {
      virtualisation.vlans = [ 1 ];
      systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";
      networking = {
        useNetworkd = true;
        useDHCP = false;
        firewall.enable = false;
        interfaces.eth1.useDHCP = true;
      };
    };
  };

  testScript = ''
    start_all()
    # Kea needs a sec to startup so well sleep
    coreServer.wait_for_unit("systemd-networkd-wait-online.service")
    coreServer.succeed("kea-dhcp4 -t /etc/kea/dhcp4-server.conf")
    client1.wait_for_unit("systemd-networkd-wait-online.service")
    client1.wait_until_succeeds("ping -c 5 10.0.3.5")
  '';
}
