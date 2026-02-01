{ inputs }:
{
  name = "loghost";

  nodes.coremaster = {
    _module.args = {
      inherit inputs;
    };
    imports = [
      inputs.self.nixosModules.default
    ];
    virtualisation.graphics = false;
    scale-network.services.rsyslogd.enable = true;
  };

  testScript = ''
    start_all()
    coremaster.succeed("sleep 2")
    coremaster.succeed("systemctl is-active syslog")
    coremaster.succeed("logger -n 127.0.0.1 -P 514 --tcp 'troyTCP'")
    coremaster.succeed("cat /persist/rsyslog/**/root.log | grep troyTCP")
    coremaster.succeed("cat /persist/rsyslog/**/messages.log | grep troyTCP")
    coremaster.succeed("logger -n 127.0.0.1 -P 514 --udp 'troyUDP'")
    coremaster.succeed("cat /persist/rsyslog/**/root.log | grep troyUDP")
    coremaster.succeed("cat /persist/rsyslog/**/messages.log | grep troyUDP")
  '';
}
