{ config, lib, pkgs, ... }:

{
  # If not present then warning and will be set to latest release during build
  system.stateVersion = "22.11";

  boot.kernelParams = [ "console=ttyS0" ];

  users.extraUsers.root.password = "";

  users.users = {
    rherna = {
      isNormalUser = true;
      uid = 2005;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEiESod7DOT2cmT2QEYjBIrzYqTDnJLld1em3doDROq" ];
    };
  };

  # disable legacy networking bits as recommended by:
  #  https://github.com/NixOS/nixpkgs/issues/10001#issuecomment-905532069
  #  https://github.com/NixOS/nixpkgs/blob/82935bfed15d680aa66d9020d4fe5c4e8dc09123/nixos/tests/systemd-networkd-dhcpserver.nix
  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall.allowedTCPPorts = [ 53 67 68 ];
    firewall.allowedUDPPorts = [ 53 67 68 ];
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    ldns
    bind
    kea
    scaleInventory
  ];

  environment.etc."bind/named.conf".source = config.services.bind.configFile;

  systemd.services.bind =
    let
      # Get original config
      cfg = config.services.bind;
    in
    {
      serviceConfig.ExecStart = lib.mkForce "${cfg.package.out}/sbin/named -u named ${lib.strings.optionalString cfg.ipv4Only "-4"} -c /etc/bind/named.conf -f";
    };

  services = {
    resolved.enable = false;
    openssh = {
      enable = true;
    };
    kea = {
      dhcp4 = {
        enable = true;
        configFile = "${pkgs.scaleInventory}/config/kea.json";
      };
    };
  };
}
