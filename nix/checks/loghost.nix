{ inputs }:
{
  name = "loghost";

  nodes.coremaster = {
    _module.args = {
      inherit inputs;
    };
    imports = [
      ../nixos-configurations/core-master/configuration.nix
      inputs.self.nixosModules.default
    ];
    virtualisation.graphics = false;
  };

  testScript = ''
    start_all()
    coremaster.succeed("sleep 2")
    coremaster.succeed("systemctl is-active syslog")
    coremaster.succeed("logger -n 127.0.0.1 -P 514 --tcp 'troy'")
    coremaster.succeed("cat /persist/rsyslog/**/root.log | grep troy")
  '';
}
