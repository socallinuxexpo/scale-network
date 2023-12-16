{ config, pkgs, ... }:
{
  boot.kernelParams = [ "console=ttyS0,115200n8" ];
  boot.loader.grub.extraConfig = "
    serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
    terminal_input serial
    terminal_output serial
  ";

  boot.tmp.cleanOnBoot = true;

  environment.systemPackages = with pkgs; [
    wget
    git
    vim
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  networking.firewall.enable = true;
  networking.useDHCP = true;
}
