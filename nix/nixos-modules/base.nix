{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.scale-network.base;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.base.enable = mkEnableOption "SCaLE network base setup";

  config = mkIf cfg.enable {
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
      gptfdisk # sgdisk, sfdisk, etc.
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
      wget
      ((vim_configurable.override { }).customize {
        name = "vim";
        # Install plugins for syntax highlighting of nix files
        vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
          start = [
            vim-nix
          ];
          opt = [ ];
        };
        vimrcConfig.customRC = ''
          " Turn on syntax highlighting by default
          syntax on
          " Disable mouse
          set mouse-=a
        '';
      })
    ];

    # Purge nano from being the default
    environment.variables = {
      EDITOR = "vim";
    };

    # set 24h military time
    i18n.extraLocaleSettings = {
      LC_TIME = "C.UTF-8";
    };

    # Force noXlibs per recommendation in microVMs
    # ref: https://github.com/astro/microvm.nix/issues/167
    environment.noXlibs = false;
  };
}
