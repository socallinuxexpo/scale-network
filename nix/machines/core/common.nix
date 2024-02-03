{ config, lib, pkgs, inputs, ... }:

{
  boot.kernelParams = [ "console=ttyS0" ];

  # disable legacy networking bits as recommended by:
  #  https://github.com/NixOS/nixpkgs/issues/10001#issuecomment-905532069
  #  https://github.com/NixOS/nixpkgs/blob/82935bfed15d680aa66d9020d4fe5c4e8dc09123/nixos/tests/systemd-networkd-dhcpserver.nix
  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall.allowedTCPPorts = [ 53 67 68 ];
    firewall.allowedUDPPorts = [ 53 67 68 123 ];
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    ldns
    bind
    kea
    inputs.self.packages.${pkgs.system}.scaleInventory
    vim
    git
  ];

  environment.etc."bind/named.conf".source = config.services.bind.configFile;

  systemd.services.bind =
    let
      # Get original config
      cfg = config.services.bind;
    in
    {
      serviceConfig.ExecStart = lib.mkForce "${cfg.package.out}/sbin/named -u named ${lib.strings.optionalString cfg.ipv4Only "-4"} -c /etc/bind/named.conf -f";
      restartTriggers = [
        cfg.configFile
      ];
    };

  services = {
    resolved.enable = false;
    openssh = {
      enable = true;
    };
    kea = {
      dhcp4 = {
        enable = true;
        configFile = "${inputs.self.packages.${pkgs.system}.scaleInventory}/config/kea.json";
      };
    };
    ntp = {
      enable = true;
      extraConfig = ''
        # Hosts on the local network(s) are not permitted because of the "restrict default"
        restrict 10.0.0.0/8 kod nomodify notrap nopeer
        restrict 2001:470:f026::/48 kod nomodify notrap nopeer
      '';
    };
  };
}
