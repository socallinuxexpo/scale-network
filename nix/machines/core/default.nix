{ config, lib, pkgs, ... }:
let
  #dhcpv4config = pkgs.scaleTemplates.gomplateFile "dhcp4" ./kea/dhcpv4.tmpl ../../../inventory.json;
in
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
  };

  # Make sure that the makes of these files are actually lexicographically before 99-default.link provides by systemd defaults since first match wins
  # Ref: https://github.com/systemd/systemd/issues/9227#issuecomment-395500679
  systemd.network = {
    enable = true;
    networks = {
      "10-lan" = {
        name = "enp0*";
        enable = true;
        address = [ "10.0.3.5/24" "2001:470:f0fb:103::5/64" ];
        gateway = [ "10.0.3.1" ];
      };
    };
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    kea
    expect
    scaleInventory
  ];

  services = {
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
