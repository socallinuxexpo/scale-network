# This test sets up all the routers and ensures that the network configs are
# picked up correctly and connectivity works as expected.
{ inputs, lib }:
{
  name = "routers";

  nodes = {
    border =
      { lib, ... }:
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
          services.frr2.enable = true;
        };
        networking.firewall.enable = false;
      };
    conference =
      { lib, ... }:
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
        };
        networking.firewall.enable = false;
      };
    expo =
      { lib, ... }:
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
        };
        networking.firewall.enable = false;
      };
  };

  testScript =
    { nodes, ... }:
    ''
      start_all()
      border.wait_for_unit("multi-user.target")
      conference.wait_for_unit("multi-user.target")
      expo.wait_for_unit("multi-user.target")

      # border can hit both routers
      border.succeed("ping -c 5 10.1.1.2")
      border.succeed("ping -c 5 10.1.2.3")

      # conference should hit neighbors
      conference.succeed("ping -c 5 10.1.1.1")
      conference.succeed("ping -c 5 10.1.3.3")

      # expo should hit neighbors
      expo.succeed("ping -c 5 10.1.2.1")
      expo.succeed("ping -c 5 10.1.3.2")
    '';
}
