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
      alloy.rsyslogdLokiScrape.enable = true;
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
      # Create the rsyslog log directory and mock data before services start reading
      coreconf.succeed("mkdir -p /persist/rsyslog/test-ap-01")
      coreconf.succeed("echo 'Jan  1 00:00:00 test-ap-01 sshd[1234]: test log entry' > /persist/rsyslog/test-ap-01/messages.log")

      coreconf.wait_for_unit("grafana.service", None, 30)
      coreconf.wait_for_unit("alloy.service", None, 30)
      coreconf.wait_until_succeeds("nc -vz localhost 3000")

      # Wait for Loki to be ready, then verify it receives the rsyslog logs
      coreconf.wait_until_succeeds("nc -vz localhost 3100")
      coreconf.wait_until_succeeds("curl -sf 'http://localhost:3100/loki/api/v1/labels' | grep -q 'source_host'")

      client1.wait_until_succeeds("ping -c 5 ${nodes.coreconf.networking.hostName}")
      # TODO: Fix flakey test
      #client1.wait_until_succeeds("curl -v -k -L -H \"Host: monitoring.scale.lan\" http://${nodes.coreconf.networking.hostName}")
    '';

  interactive.sshBackdoor.enable = true;

  # TODO:
  # - Create machine that replays AP data
  # - Validate prometheus is collecting data
  # - Validate grafana dashboard is presenting data from Prometheus
}
