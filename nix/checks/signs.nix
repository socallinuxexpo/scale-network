{ inputs }:
{
  name = "signs";

  nodes.coremaster = {
    _module.args = {
      inherit inputs;
    };
    imports = [
      inputs.self.nixosModules.default
    ];
    networking.nameservers = [
      "8.8.8.8"
    ];
    # networking.useDHCP = true;
    # nix.settings.sandbox = false;
    scale-network.services.signs.enable = true;
    # virtualisation.graphics = true;
  };

  nodes.client1 =
    { pkgs, ... }:
    {
      systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";
      # networking.useDHCP = true;
      # nix.settings.sandbox = false;
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
      client1.wait_for_unit("multi-user.target")
      client1.succeed("ping -c 3 8.8.8.8")
      client1.succeed("ping -c 3 google.com")
      coremaster.wait_for_unit("podman-scale-signs.service", None, 230)

      client1.wait_until_succeeds("ping -c 5 ${nodes.coremaster.networking.hostName}")
      client1.wait_until_succeeds("curl -v -L -H \"Host: signs.scale.lan\" http://${nodes.coremaster.networking.hostName}")
    '';

  # TODO:
  # - Create machine that replays AP data
  # - Validate prometheus is collecting data
  # - Validate grafana dashboard is presenting data from Premetheus
}
