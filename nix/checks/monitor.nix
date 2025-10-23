{inputs}: {
  name = "monitor";

  nodes.coremaster = {
    _module.args = {
      inherit inputs;
    };
    imports = [
      ../nixos-modules/services/monitoring.nix
      inputs.self.nixosModules.default
    ];
    virtualisation.graphics = true;
    scale-network.services.monitoring.enable = true;
  };

  nodes.client1 = {pkgs, ...}: {
    systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";
    environment = {
      systemPackages = with pkgs; [
        curl
      ];
    };
  };

  testScript = {nodes, ...}: ''
    start_all()
    coremaster.succeed("sleep 2")
    coremaster.wait_for_unit("grafana.service", None, 30)
    coremaster.wait_for_unit("prometheus.service", None, 30)
    coremaster.wait_until_succeeds("nc -vz localhost 3000")

    client1.wait_until_succeeds("ping -c 5 ${nodes.coremaster.networking.hostName}")
    client1.wait_until_succeeds("curl -v -L -H \"Host: monitoring.scale.lan\" http://${nodes.coremaster.networking.hostName}")
  '';

  interactive.sshBackdoor.enable = true;

  # TODO:
  # - Create machine that replays AP data
  # - Validate prometheus is collecting data
  # - Validate grafana dashboard is presenting data from Premetheus
}
