{ config, lib, pkgs, ... }:

{
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

  };

}
