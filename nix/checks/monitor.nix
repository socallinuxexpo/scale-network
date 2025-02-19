{
  name = "monitor";

  nodes.monitor = {
    imports = [
      ../nixos-configurations/monitor/configuration.nix
    ];
    virtualisation.graphics = true;
  };

  testScript = ''
    start_all()
    monitor.succeed("sleep 2")
    monitor.succeed("systemctl is-active grafana")
    monitor.succeed("systemctl is-active prometheus")
    monitor.fail("systemctl is-active nginx")
    monitor.fail("systemctl status nginx")
    monitor.systemctl("status nginx.service")
    monitor.wait_until_succeeds("nc -vz localhost 3000")
    monitor.fail("nc -vz localhost 80")
  '';

  # TODO:
  # - Create machine that replays AP data
  # - Validate prometheus is collecting data
  # - Validate grafana dashboard is presenting data from Premetheus
}
