{ config, pkgs, ... }:
let
  # without readFile the bootstrap script is not executable because its referenced to its path as regular file in the store
  # ref: https://discourse.nixos.org/t/cannot-run-basic-shell-using-writeshellscriptbin/28835/2
  mybootstrap = pkgs.writeShellScriptBin "mybootstrap" (builtins.readFile ./bootstrap.sh);
in
{
  # remove the annoying experimental warnings
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  networking = {
    # use systemd.networkd
    useNetworkd = true;
    useDHCP = false;
    firewall.enable = true;
  };

  systemd.network = {
    enable = true;
    networks = {
      "10-lan" = {
        matchConfig.Name = "eno1";
        enable = true;
        networkConfig.DHCP = "yes";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    wget
    git
    vim
    efibootmgr
    gptfdisk
    screen
    mybootstrap
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;
  };
}
