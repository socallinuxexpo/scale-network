{ inputs, lib }:
{
  name = "borderrouter";

  nodes = {
    borderrouter =
      { lib, ... }:
      {
        _module.args = {
          inherit inputs;
        };
        imports = [
          inputs.self.nixosModules.default
        ];

        virtualisation.vlans = [
          1
          2
          3
        ];
        scale-network = {
          router.border.enable = true;
        };
      };
  };

  testScript =
    { nodes, ... }:

    ''
      start_all()
      print(borderrouter.succeed("ip -br addr show"))
    '';

}
