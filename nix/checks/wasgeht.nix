{ inputs }:
{
  name = "wasgeht";

  nodes.coremaster = {
    _module.args = {
      inherit inputs;
    };
    imports = [
      inputs.self.nixosModules.default
    ];
    virtualisation.graphics = true;
    scale-network.services.wasgeht.enable = true;
  };

  nodes.client1 =
    { pkgs, ... }:
    {
      systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";
      environment = {
        systemPackages = with pkgs; [
          curl
        ];
      };
    };

  testScript =
    { nodes, ... }:
    ''
      start_all()
      coremaster.succeed("sleep 2")
      coremaster.wait_for_unit("wasgeht.service", None, 30)
      coremaster.wait_until_succeeds("nc -vz localhost 1982")

      client1.wait_until_succeeds("curl -v http://${nodes.coremaster.networking.hostName}:1982")
    '';

}
