{
  pkgs,
  ...
}:

{
  # remove the annoying experimental warnings
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  networking = {
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
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;
  };
}
