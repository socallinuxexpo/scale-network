{ config, pkgs, ... }:
{
  boot = {
    kernelParams = [ "console=ttyS0,115200n8" ];
    loader.grub.extraConfig = "
    serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
    terminal_input serial
    terminal_output serial
    ";
  };

  #boot.supportedFilesystems = [ "zfs" ];

  # remove the annoying experimental warnings
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  networking = {
    useNetworkd = true;
    useDHCP = false;
    firewall.enable = true;
  };

  # https://nixos.wiki/wiki/Systemd-networkd#Bonding
  systemd.network = {
    enable = true;
    networks = {
      "10-lan" = {
        matchConfig.Name = "eno1";
        enable = true;
        networkConfig.DHCP = "yes";
        # this port is not always connected and not required to be online
        linkConfig.RequiredForOnline = "no";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    wget
    git
    vim
    efibootmgr
    gptfdisk
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;
  };
}
