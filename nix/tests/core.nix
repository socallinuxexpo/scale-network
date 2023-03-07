{
  name = "core";
  nodes = {
    coreServer = { lib, ... }: {
      imports = [ ../machines/core/master.nix ];
    } // {
      virtualisation.vlans = [ 1 ];
      virtualisation.graphics = false;
      systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";
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
      environment = {
        systemPackages = with pkgs; [
          ldns
        ];
      };
    };

  };
  testScript = ''
    start_all()
    coreServer.wait_for_unit("systemd-networkd-wait-online.service")
    coreServer.succeed("kea-dhcp4 -t /etc/kea/dhcp4-server.conf")
    client1.wait_for_unit("systemd-networkd-wait-online.service")
    client1.wait_until_succeeds("ping -c 5 10.0.3.5")
    # Have to wrap drill since retcode isnt necessarily 1 on query failure
    client1.wait_until_succeeds("test ! -z \"$(drill -Q -z scale.lan SOA)\"")
    client1.wait_until_succeeds("test ! -z \"$(drill -Q -z coreexpo.scale.lan A)\"")
    client1.wait_until_succeeds("test ! -z \"$(drill -Q -z coreexpo.scale.lan AAAA)\"")
    client1.wait_until_succeeds("test ! -z \"$(drill -Q -z -x 10.0.3.5)\"")
  '';
}
