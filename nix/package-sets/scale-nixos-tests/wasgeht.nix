{ inputs }:
{
  name = "wasgeht";

  nodes.coreconf = {
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
      coreconf.wait_for_unit("wasgeht.service", None, 30)
      coreconf.wait_until_succeeds("nc -vz localhost 1982", timeout=60)
      coreconf.wait_until_succeeds("curl -v --fail http://localhost:1982", timeout=60)
      coreconf.wait_until_succeeds("curl -v --fail http://localhost:1982/imgs", timeout=60)
      coreconf.wait_until_succeeds("curl -v --fail http://localhost:1982/api", timeout=60)
      coreconf.wait_until_succeeds("curl -v --fail http://localhost:1982/metrics", timeout=60)
    '';
}
