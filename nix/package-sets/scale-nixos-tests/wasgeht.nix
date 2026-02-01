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
      coremaster.wait_for_unit("wasgeht.service", None, 30)
      coremaster.succeed("nc -vz localhost 1982")
      coremaster.succeed("curl -v --fail http://localhost:1982")
      coremaster.succeed("curl -v --fail http://localhost:1982/imgs")
      coremaster.succeed("curl -v --fail http://localhost:1982/api")
      coremaster.succeed("curl -v --fail http://localhost:1982/metrics")
    '';
}
