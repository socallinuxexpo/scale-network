{ config, lib, pkgs, ... }:

{

  security.sudo = {
    extraConfig = ''
      Defaults rootpw
      Defaults lecture="never"
    '';
  };

  users.mutableUsers = false;
  users.extraUsers.root.hashedPassword = "$6$3Hm/K5fbR3UEMK6H$3aaegtdwvejGk9Bk0ttN5bNJn4z2Yt6LWXD3nGI7.44Pbm7A1TpKuxG9XQLwsj7M9NEk8eB5Exg0qVRV//6br/";

  users.users = {
    rob = {
      isNormalUser = true;
      uid = 2005;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEiESod7DOT2cmT2QEYjBIrzYqTDnJLld1em3doDROq" ];
    };
    owen = {
      isNormalUser = true;
      uid = 2006;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBjjcUJLTENGrV6K/nrPOswcBVMMuS4sLSs0UyTRw8wU87PDUzJz8Ht2SgHqeEQJdRm1+b6iLsx2uKOf+/pU8qE= root@kiev.delong.com" ];
    };
    dlang = {
      isNormalUser = true;
      uid = 2008;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEqPnzsYPKyURdnUpZx1nt9RFQjaz9q7m5wh525Crsho" ];
    };
    kylerisse = {
      isNormalUser = true;
      uid = 2007;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPcTYYr/TGH4vRCaY4WU4Qc7RlzzBOHv2XYxGwCzV+fg p"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKX8NM1OQECwhNTQE0qAm422uq9L0i0Y/hvPPc4tHIOX a"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlEPbMnefiPfCTKb9lOzPzfnOVAohO08myWWMm9EJxZ"
      ];
    };
    ruebenramirez = {
      isNormalUser = true;
      uid = 2009;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAkQS5ohCDizq24WfDgP/dEOonD/0WfrI0EAZFCyS0Ea" ];
    };
    rhamel = {
      isNormalUser = true;
      uid = 2010;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICVZ7n1EOezedsbphq5atGtHm11xeGpLZBzEbgV7eZdb" ];
    };
  };

}
