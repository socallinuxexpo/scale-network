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
      coremaster.succeed("curl -v http://localhost:1982")
      coremaster.succeed("curl -v http://localhost:1982/imgs")
      coremaster.succeed("curl -v http://localhost:1982/api")
      coremaster.wait_until_succeeds("test -f /persist/var/lib/wasgeht/rrds/localhost_latency.rrd")
      coremaster.wait_until_succeeds("journalctl -u wasgeht --no-pager | grep localhost | grep 'Ping successful'")
      coremaster.wait_until_succeeds("test -f /persist/var/lib/wasgeht/graphs/imgs/localhost/localhost_latency_15m.png")

      client1.succeed("curl -v http://${nodes.coremaster.networking.hostName}:1982")
      client1.succeed("curl -q http://${nodes.coremaster.networking.hostName}:1982/api | grep true")
      client1.succeed("curl -v http://${nodes.coremaster.networking.hostName}:1982/imgs/localhost/localhost_latency_15m.png")
    '';
}
