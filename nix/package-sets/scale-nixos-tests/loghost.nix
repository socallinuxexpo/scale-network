{ inputs }:
{
  name = "loghost";

  nodes.coreconf = {
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
    coreconf.succeed("sleep 2")
    coreconf.succeed("systemctl is-active syslog")
    coreconf.succeed("logger -n 127.0.0.1 -P 514 --tcp 'troyTCP'")
    coreconf.succeed("cat /persist/rsyslog/**/root.log | grep troyTCP")
    coreconf.succeed("cat /persist/rsyslog/**/messages.log | grep troyTCP")
    coreconf.succeed("logger -n 127.0.0.1 -P 514 --udp 'troyUDP'")
    coreconf.succeed("cat /persist/rsyslog/**/root.log | grep troyUDP")
    coreconf.succeed("cat /persist/rsyslog/**/messages.log | grep troyUDP")
  '';
}
