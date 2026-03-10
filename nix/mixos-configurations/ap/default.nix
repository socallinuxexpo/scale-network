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
    process = toString [
      (lib.getExe pkgs.prometheus-node-exporter)
      "--collector.wifi"
    ];
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

      for bridge in br-lan scaleslow-br scalefast-br mgmt-br; do
        ip link add "$bridge" type bridge stp on
      done

      for link in eth0 eth1; do
        ip link set dev "$link" master br-lan
      done

      for vlan_id in 100 500 101 501 103 503; do
        ip link add link br-lan name "br-lan.''${vlan_id}" type vlan id "$vlan_id"
      done

      for vlan_id in 100 500; do
        ip link set dev "br-lan.''${vlan_id}" master scaleslow-br
      done

      for vlan_id in 101 501; do
        ip link set dev "br-lan.''${vlan_id}" master scalefast-br
      done

      for vlan_id in 103 503; do
        ip link set dev "br-lan.''${vlan_id}" master mgmt-br
      done

      # mgmt-br brought up via DHCP
      for link in eth0 eth1 br-lan scaleslow-br scalefast-br; do
        ip link set "$link" up
      done
    '';
  };
}
