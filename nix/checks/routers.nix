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
        ];
        scale-network = {
          base.enable = true;
          router.conference = {
            enable = true;
            frrBorderInterface = "eth1";
            frrExpoInterface = "eth2";
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
        ];
        scale-network = {
          base.enable = true;
          router.expo = {
            enable = true;
            frrBorderInterface = "eth1";
            frrConferenceInterface = "eth2";
          };
        };
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

      # layer 2
      print("LAYER 2")

      # border can ping both routers
      border.succeed("ping -c 5 10.1.1.2")
      border.succeed("ping -c 5 10.1.2.3")

      # conference can ping both routers
      conference.succeed("ping -c 5 10.1.1.1")
      conference.succeed("ping -c 5 10.1.3.3")

      # expo can ping both routers
      expo.succeed("ping -c 5 10.1.2.1")
      expo.succeed("ping -c 5 10.1.3.2")

      # layer 3
      print("LAYER 3")

      border.wait_for_unit("frr.service")
      conference.wait_for_unit("frr.service")
      expo.wait_for_unit("frr.service")

      # border can reach conference-expo link
      border.succeed("ping -c 5 10.1.3.2")
      border.succeed("ping -c 5 10.1.3.3")

      # conference can reach border-expo link
      conference.succeed("ping -c 5 10.1.2.1")
      conference.succeed("ping -c 5 10.1.2.3")

      # expo can reach conference-border link
      expo.succeed("ping -c 5 10.1.1.1")
      expo.succeed("ping -c 5 10.1.1.2")

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
