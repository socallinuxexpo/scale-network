{ config, lib, pkgs, ... }:
{
  # If not present then warning and will be set to latest release during build
  system.stateVersion = "22.11";

  boot.kernelParams = [ "console=ttyS0" ];

  # TODO: How to handle to the root password
  users.extraUsers.root.password = "";

  # TODO: Consume users from facts/keys instead of this
  users.users = {
    rherna = {
      isNormalUser = true;
      uid = 2005;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEiESod7DOT2cmT2QEYjBIrzYqTDnJLld1em3doDROq" ];
    };
  };

  # TODO: How to handle sudo esculation
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    rsyslog
  ];

  # Easy test of the service using logger
  # logger -n 127.0.0.1 -P 514 --tcp "simple test"
  # cat /var/log/rsyslog/<hostname>/root.log
  services.rsyslogd = {
    enable = true;
    defaultConfig = ''
      module(load="imtcp")
      input(type="imtcp" port="514")

      $template RemoteLogs,"/var/log/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log"
      *.* ?RemoteLogs
      & ~
    '';
  };
}
