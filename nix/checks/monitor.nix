{ inputs }:
{
  name = "monitor";

  nodes.coremaster = {
    _module.args = {
      inherit inputs;
    };
    imports = [
      ../nixos-configurations/core-master/configuration.nix
      inputs.self.nixosModules.default
    ];
    virtualisation.graphics = true;
  };

  testScript = ''
    start_all()
    coremaster.succeed("sleep 2")
    coremaster.succeed("systemctl is-active grafana")
    coremaster.succeed("systemctl is-active prometheus")
    coremaster.wait_until_succeeds("nc -vz localhost 3000")
  '';

  # TODO:
  # - Create machine that replays AP data
  # - Validate prometheus is collecting data
  # - Validate grafana dashboard is presenting data from Premetheus
}
