{
  writeShellApplication,
  dnsmasq,
}:
writeShellApplication {
  name = "make-dhcpd";

  runtimeInputs = [ dnsmasq ];

  bashOptions = [ ];

  text = builtins.readFile ./make-dhcpd.sh;
}
