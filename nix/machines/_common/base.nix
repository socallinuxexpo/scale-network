{ config, pkgs, ... }:
{
  # default to stateVersion for current lock
  system.stateVersion = config.system.nixos.version;

  # remove the annoying experimental warnings
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  environment.systemPackages = with pkgs; [
    bc
    binutils
    btop
    cachix
    curl
    dig
    dmidecode
    file
    git
    git-lfs
    gptfdisk #sgdisk, sfdisk, etc.
    inetutils # telnet,ftp,etc
    iproute2
    jq
    lsof
    mtr
    nmap
    openssh
    openssl
    pciutils
    psmisc # fuser
    silver-searcher
    strace
    tcpdump
    tmux
    usbutils
    unixtools.nettools
    vim
    wget
  ];

  # Purge nano from being the default
  environment.variables = { EDITOR = "vim"; };
}
