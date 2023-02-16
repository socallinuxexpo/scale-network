{
  name = "core";
  nodes.machine1 = { ... }: { imports = [ ../machines/core ]; } // {
    virtualisation.graphics = false;
  };

  testScript = ''
    start_all()
    # Kea needs a sec to startup so well sleep
    machine1.succeed("sleep 10")
    machine1.succeed("kea-dhcp4 -t /etc/kea/dhcp4-server.conf")
    machine1.succeed("systemctl is-active kea-dhcp4-server")
  '';
}
