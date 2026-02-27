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
    system.stateVersion = config.system.nixos.release;

    system.activationScripts.syncRepo = {
      # will run after "etc" (which updates /etc symlinks).
      deps = [ "etc" ];

      # ensure we have a local copy of scale-network and fetch
      # this does not update the local branch in the repo, it
      # only updates the local remote refs
      text = ''
        REPO_URL="https://github.com/socallinuxexpo/scale-network"
        REPO_DIR="/root/scale-network"

        if [ ! -d "$REPO_DIR" ]; then
            echo "Cloning repository..."
            ${lib.getExe pkgs.git} clone "$REPO_URL" "$REPO_DIR"
        else
            echo "Repository exists. Fetching updates..."
            ${lib.getExe pkgs.git} -C "$REPO_DIR" fetch --all --prune
        fi
      '';
    };

    # remove the annoying experimental warnings
    nix.extraOptions = ''
      experimental-features = nix-command flakes
    '';

    # Enable deployments by non-root user.
    nix.settings.trusted-users = [ "@wheel" ];

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
      nettools
      wget
    ];

    programs.vim = {
      enable = true;
      defaultEditor = true;
      package = (pkgs.vim_configurable.override { }).customize {
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
      };
    };

    # set 24h military time
    i18n.extraLocaleSettings = {
      LC_TIME = "C.UTF-8";
    };
  };
}
