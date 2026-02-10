{ inputs }:
{
  name = "monitor";

  nodes.coreconf = {
    _module.args = {
      inherit inputs;
    };
    imports = [
      inputs.self.nixosModules.default
    ];
    virtualisation.graphics = true;
    scale-network.services = {
      monitoring.enable = true;
      alloy.enable = true;
    };
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
      coreconf.succeed("sleep 2")
      coreconf.wait_for_unit("grafana.service", None, 30)
      coreconf.wait_for_unit("alloy.service", None, 30)
      coreconf.wait_until_succeeds("nc -vz localhost 3000")

      client1.wait_until_succeeds("ping -c 5 ${nodes.coreconf.networking.hostName}")
      # TODO: Fix flakey test
      #client1.wait_until_succeeds("curl -v -k -L -H \"Host: monitoring.scale.lan\" http://${nodes.coreconf.networking.hostName}")
    '';

  interactive.sshBackdoor.enable = true;

  # TODO:
  # - Create machine that replays AP data
  # - Validate prometheus is collecting data
  # - Validate grafana dashboard is presenting data from Premetheus
}
