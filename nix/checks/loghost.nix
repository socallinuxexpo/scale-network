{
  name = "loghost";

  nodes.machine1 = {
    imports = [ ../machines/loghost.nix ];
    virtualisation.graphics = false;
  };

  testScript = ''
    start_all()
    machine1.succeed("sleep 2")
    machine1.succeed("systemctl is-active syslog")
    machine1.succeed("logger -n 127.0.0.1 -P 514 --tcp 'troy'")
    machine1.succeed("cat /var/log/**/**/root.log | grep troy")
  '';
}
