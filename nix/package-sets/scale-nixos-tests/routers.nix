# This test sets up all the routers and ensures that the network configs are
# picked up correctly and connectivity works as expected.
{ inputs }:
{
  name = "routers";

  nodes = {
    border =
      {
        pkgs,
        ...
      }:
      {
        _module.args = {
          inherit inputs;
        };
        imports = [
          inputs.self.nixosModules.default
        ];
        virtualisation.vlans = [
          10 # NAT
          2 # border <-> conference
          3 # border <-> expo
        ];

        scale-network = {
          base.enable = true;
          router.border = {
            enable = true;
            staticWANEnable = true;
            WANInterface = "eth1";
            frrConferenceInterface = "eth2";
            frrExpoInterface = "eth3";
          };
        };
      };
    conference =
      { ... }:
      {
        _module.args = {
          inherit inputs;
        };
        imports = [
          inputs.self.nixosModules.default
        ];
        virtualisation.vlans = [
          2 # border <-> conference
          4 # conference <-> expo
          5
          6
        ];
        scale-network = {
          base.enable = true;
          router.conference = {
            enable = true;
            frrBorderInterface = "eth1";
            frrExpoInterface = "eth2";
            trunkInterfaces = [
              "eth3"
              "eth4"
            ];
          };
        };
      };
    expo =
      { ... }:
      {
        _module.args = {
          inherit inputs;
        };
        imports = [
          inputs.self.nixosModules.default
        ];
        virtualisation.vlans = [
          3 # border <-> expo
          4 # conference <-> expo
          7
        ];
        scale-network = {
          base.enable = true;
          router.expo = {
            enable = true;
            frrBorderInterface = "eth1";
            frrConferenceInterface = "eth2";
            trunkInterfaces = [
              "eth3"
            ];
          };
        };
        networking.firewall.enable = false;
      };

    client =
      {
        pkgs,
        ...
      }:
      {

        virtualisation.vlans = [
          10 # NAT
        ];

        networking.firewall.enable = false;

        networking.useNetworkd = true;
        systemd.network.networks."10-inet" = {
          matchConfig.Name = "eth1";
          networkConfig.DHCP = false;
          address = [
            "172.16.1.100/24"
          ];
        };

      };

  };

  testScript =
    { ... }:
    ''
      start_all()
      border.wait_for_unit("multi-user.target")
      conference.wait_for_unit("multi-user.target")
      expo.wait_for_unit("multi-user.target")
      client.wait_for_unit("multi-user.target")

      print("misc daemons check")

      conference.wait_for_unit("radvd.service")
      conference.wait_for_unit("dhcp4-relay-tech.service")
      conference.wait_for_unit("dhcp6-relay-tech.service")
      conference.wait_for_unit("dhcp4-relay-av.service")
      conference.wait_for_unit("dhcp6-relay-av.service")
      expo.wait_for_unit("radvd.service")
      expo.wait_for_unit("dhcp4-relay-tech.service")
      expo.wait_for_unit("dhcp6-relay-tech.service")

      # layer 2
      print("LAYER 2")

      # border can ping both routers
      border.succeed("ping -c 5 172.20.1.2")
      border.succeed("ping -c 5 2001:470:f026:901::2")
      border.succeed("ping -c 5 172.20.4.3")
      border.succeed("ping -c 5 2001:470:f026:104::3")

      # conference can ping both routers
      conference.succeed("ping -c 5 172.20.1.1")
      conference.succeed("ping -c 5 2001:470:f026:901::1")
      conference.succeed("ping -c 5 172.20.3.3")
      conference.succeed("ping -c 5 2001:470:f026:903::3")

      # expo can ping both routers
      expo.succeed("ping -c 5 172.20.4.1")
      expo.succeed("ping -c 5 2001:470:f026:104::1")
      expo.succeed("ping -c 5 172.20.3.2")
      expo.succeed("ping -c 5 2001:470:f026:903::2")

      # layer 3
      print("LAYER 3")

      border.wait_for_unit("frr.service")
      conference.wait_for_unit("frr.service")
      expo.wait_for_unit("frr.service")

      # border can reach conference-expo link
      border.wait_until_succeeds("ping -c 5 172.20.3.2", timeout=60)
      border.wait_until_succeeds("ping -c 5 2001:470:f026:903::2", timeout=60)
      border.wait_until_succeeds("ping -c 5 172.20.3.3", timeout=60)
      border.wait_until_succeeds("ping -c 5 2001:470:f026:903::3", timeout=60)

      # conference can reach border-expo link
      conference.wait_until_succeeds("ping -c 5 172.20.4.1", timeout=60)
      conference.wait_until_succeeds("ping -c 5 2001:470:f026:104::1", timeout=60)
      conference.wait_until_succeeds("ping -c 5 172.20.4.3", timeout=60)
      conference.wait_until_succeeds("ping -c 5 2001:470:f026:104::3", timeout=60)

      # expo can reach conference-border link
      expo.wait_until_succeeds("ping -c 5 172.20.1.1", timeout=60)
      expo.wait_until_succeeds("ping -c 5 2001:470:f026:901::1", timeout=60)
      expo.wait_until_succeeds("ping -c 5 172.20.1.2", timeout=60)
      expo.wait_until_succeeds("ping -c 5 2001:470:f026:901::2", timeout=60)

      # NAT
      print("NETCAT")

      client.execute("nc -l 1234 -k -v -n 2> netcat.log 1>&2 &", timeout=10)
      border.succeed("nc -z 172.16.1.100 1234", timeout=10)
      expo.succeed("nc -z 172.16.1.100 1234", timeout=10)
      conference.succeed("nc -z 172.16.1.100 1234", timeout=10)
      client.succeed("cat netcat.log 1>&2", timeout=5)
      client.succeed("test 3 == $(grep 172.16.1.1 -c netcat.log)", timeout=5)
    '';

  interactive.sshBackdoor.enable = true;
}
