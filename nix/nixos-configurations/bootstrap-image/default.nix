{
  release = "unstable";

  modules =
    {
      lib,
      modulesPath,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules)
        mkForce
        ;
    in
    {
      imports = [
        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
      ];

      config = {
        nixpkgs.hostPlatform = "x86_64-linux";

        scale-network = {
          base.enable = true;

          users.berkhan.enable = true;
          users.dlang.enable = true;
          users.jsh.enable = true;
          users.kylerisse.enable = true;
          users.owen.enable = true;
          users.rhamel.enable = true;
          users.rob.enable = true;
          users.root.enable = true;
          users.ruebenramirez.enable = true;
        };

        nix.extraOptions = ''
          experimental-features = nix-command flakes
        '';

        networking = {
          useNetworkd = true;
          useDHCP = false;
          # disabled by default but since were pulling in:
          # installer/cd-dvd/installation-cd-minimal.nix
          #
          # nm will also get an IP address if left alone
          # had attributes: secondary dynamic noprefixroute
          networkmanager.enable = mkForce false;
          firewall.enable = true;
        };

        systemd.network = {
          enable = true;
          networks = {
            "10-lan" = {
              matchConfig.Type = "ether";
              enable = true;
              networkConfig.DHCP = "yes";
            };
            "10-wlan" = {
              matchConfig.Type = "wlan";
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
      };
    };
}
