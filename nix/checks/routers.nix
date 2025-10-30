# This test sets up all the routers and ensures that the network configs are
# picked up correctly and connectivity works as expected.
{ inputs }:
{
  name = "routers";

  nodes = {
    border =
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
          3 # border <-> expo
        ];
        scale-network = {
          base.enable = true;
          router.border.enable = true;
          services.frr.enable = true;
          services.frr.router-id = "10.1.1.1";
          services.frr.passive-interfaces = [
            "eth0"
          ];
          services.frr.broadcast-interface = [
            "eth1"
            "eth2"
          ];
        };
        networking.firewall.enable = false;
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
          router.conference.enable = true;
          services.frr.enable = true;
          services.frr.router-id = "10.1.1.2";
          services.frr.passive-interfaces = [
            "eth0"
          ];
          services.frr.broadcast-interface = [
            "eth1"
            "eth2"
          ];
        };
        networking.firewall.enable = false;
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
          router.expo.enable = true;
          services.frr.enable = true;
          services.frr.router-id = "10.1.2.3";
          services.frr.passive-interfaces = [
            "eth0"
          ];
          services.frr.broadcast-interface = [
            "eth1"
            "eth2"
          ];
        };
        networking.firewall.enable = false;
      };
  };

  testScript =
    { ... }:
    ''
      start_all()
      border.wait_for_unit("multi-user.target")
      conference.wait_for_unit("multi-user.target")
      expo.wait_for_unit("multi-user.target")

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
    '';

  interactive.sshBackdoor.enable = true;
}
