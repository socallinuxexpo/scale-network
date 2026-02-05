{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.scale;
in
{
  imports = [ ./options.nix ];

  nixpkgs.buildPlatform = "x86_64-linux";
  hardware.openwrt-one.enable = true;

  bin = [
    pkgs.hostapd
    pkgs.iw
    pkgs.libgpiod
    pkgs.lldpd
    pkgs.mtdutilsMinimal
    pkgs.net-tools
    pkgs.nftables
    pkgs.phytool
    pkgs.scale-network.apinger
    pkgs.openssh
    (
      # Provide a "wifi" program that allows for quickly enabling/disabling all
      # wireless interfaces
      pkgs.writeScriptBin "wifi" (lib.fileContents ./wifi.sh)
    )
  ];

  # Provide a template for the apinger configuration, as well as a sane default
  # starting point with a populated template.
  etc."apinger.tmpl".source = ./apinger.conf;
  etc."apinger.conf".source = pkgs.replaceVars ./apinger.conf {
    DEFAULTGATEWAY = "1.1.1.1";
  };

  etc."lldpd.conf".source = pkgs.writeText "lldpd.conf" ''
    # LLDP frames are link-local frames, do not use any
    # network interfaces other than the ones that achieve
    # a link with its link partner, and the link partner
    # being another networking device. Do not use bridge,
    # VLAN, or DSA conduit interfaces.
    #
    # lldp unable to receive frames on mediatek due to bug
    # ref: https://github.com/openwrt/openwrt/issues/13788

    # lldp will default to listening on all interfaces

    # Set class of device
    configure class 4

    configure system description "MT7981b SCaLE OpenWrt"
  '';

  etc."ntp.conf".source = pkgs.writeText "ntp.conf" ''
    server 0.nixos.pool.ntp.org iburst
    server 1.nixos.pool.ntp.org iburst
    server 2.nixos.pool.ntp.org iburst
    server 3.nixos.pool.ntp.org iburst
  '';

  etc."ssh/sshd_config".source = pkgs.writeText "sshd_config" ''
    Port 22
    PermitRootLogin yes
    PasswordAuthentication ${if cfg.passwordAuth then "yes" else "no"}
    ChallengeResponseAuthentication ${if cfg.passwordAuth then "yes" else "no"}
    AuthorizedKeysFile %h/.ssh/authorized_keys
    LogLevel VERBOSE
  '';

  etc."ssl".source = "${pkgs.cacert}/etc/ssl";

  init.leds = {
    action = "once";
    process = pkgs.writeScript "leds.sh" ''
      #!/bin/sh

      echo 1 >/sys/class/leds/green:status/brightness
    '';
  };

  init.ssh-keygen = {
    action = "wait";
    process = pkgs.writeScript "ssh-keygen" ''
      #!/bin/sh

      if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
        ssh-keygen -t ed25519 -N "" -f /etc/ssh/ssh_host_ed25519_key
      fi
    '';
  };

  init.sshd = {
    action = "respawn";
    process = lib.getExe' pkgs.openssh "sshd";
  };

  init.syslogd.process = "/bin/syslogd -n -D -L -R loghost.scale.lan";

  init.shell = {
    tty = "ttyS0";
    action = "askfirst";
    process = "/bin/sh";
  };

  users.root = {
    uid = 0;
    gid = 0;
    description = "System administrator";
    home = "/root";
    shell = "/bin/sh";
  };

  users._lldpd = {
    uid = 1;
    gid = 1;
  };

  users.sshd = {
    uid = 2;
    gid = 2;
  };

  groups.root.id = 0;
  groups._lldpd.id = 1;
  groups.sshd.id = 2;
  groups.nogroup.id = 999;

  init.prometheus-node-exporter = {
    action = "respawn";
    process = lib.getExe pkgs.prometheus-node-exporter;
  };

  init.apinger = {
    action = "respawn";
    process = "${lib.getExe pkgs.scale-network.apinger} -f -c /etc/apinger.conf";
  };

  init.lldpd = {
    action = "respawn";
    process = "${lib.getExe' pkgs.lldpd "lldpd"} -d";
  };

  init.hostapd = {
    action = "respawn";
    process = "${lib.getExe' pkgs.hostapd "hostapd"} ${./hostapd-scaleslow.conf}";
  };

  init.udhcpc = {
    action = "respawn";
    process = "/bin/udhcpc -f -S -i mgmt-br -O 224 -O 225 -O 226 -s ${pkgs.writeScript "udhcpc-script.sh" ''
      #!/bin/sh
      ${pkgs.busybox}/default.script "$@"
      ${lib.fileContents ./udhcpc-script.sh}
    ''}";
  };

  init.create-interfaces = {
    action = "wait";
    process = pkgs.writeScript "create-interfaces.ash" ''
      #!/bin/sh

      set -x

      ip link add br-lan type bridge stp on
      ip link add scaleslow-br type bridge stp on
      ip link add scalefast-br type bridge stp on
      ip link add mgmt-br type bridge stp on
      ip link set dev eth0 master br-lan
      ip link set dev eth1 master br-lan
      ip link add link br-lan name br-lan.100 type vlan id 100
      ip link add link br-lan name br-lan.500 type vlan id 500
      ip link add link br-lan name br-lan.101 type vlan id 101
      ip link add link br-lan name br-lan.501 type vlan id 501
      ip link add link br-lan name br-lan.103 type vlan id 103
      ip link add link br-lan name br-lan.503 type vlan id 503
      ip link set dev br-lan.100 master scaleslow-br
      ip link set dev br-lan.500 master scaleslow-br
      ip link set dev br-lan.101 master scalefast-br
      ip link set dev br-lan.501 master scalefast-br
      ip link set dev br-lan.103 master mgmt-br
      ip link set dev br-lan.503 master mgmt-br
      ip link set eth0 up
      ip link set eth1 up
      ip link set br-lan up
    '';
  };
}
