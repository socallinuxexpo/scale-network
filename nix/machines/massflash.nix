{ config, lib, pkgs, inputs, ... }:
let
  addtobr = pkgs.writeShellScriptBin "addtobr" ''
    [ -z "$1" ] && echo "Please pass in network device" && exit 1
    ip link set $1 master br0
    bridge vlan add dev $1 vid 503
    ip link set $1 up
    '';
in
{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };
  boot.growPartition = true;
  # Todo: figure out console+monitor output
  #boot.kernelParams = [ "console=ttyS0" ];
  boot.loader.grub.device = "/dev/vda";

  systemd.network = {
    enable = true;
    netdevs = {
      br0 = {
        netdevConfig = { Kind = "bridge"; Name = "br0"; };
        extraConfig = ''
        [Bridge]
        VLANFiltering=1
        '';
      };

      flash = {
        netdevConfig = { Kind = "veth"; Name = "flash0"; };
        peerConfig = { Name = "flash1"; };
      };
      flash503 = {
        vlanConfig = { Id = 503; };
        netdevConfig = { Kind = "vlan"; Name = "flash0.503"; };
      };
    };
    # Nice example: https://github.com/NixOS/nixpkgs/issues/16230#issuecomment-272331072
    networks = {
      # Requires a match to automatically bring up the interface
      br0.extraConfig = ''
        [Match]
        Name=br0
      '';
      flash0.extraConfig = ''
        [Match]
        Name=flash0

        [Network]
        VLAN=flash0.503
      '';
      flash503.extraConfig = ''
        [Match]
        Name=flash0.503

        [Network]
        Address=192.168.252.1/22
      '';
      flash1.extraConfig = ''
        [Match]
        Name=flash1

        [Network]
        Bridge=br0

        [BridgeVLAN]
        VLAN=503
      '';
    };
  };
  networking = {
    useDHCP = false;
    # Make sure that dhcpcd doesnt timeout when interfaces are down
    # ref: https://nixos.org/manual/nixos/stable/options.html#opt-networking.dhcpcd.wait
    dhcpcd.wait = "background";
    hostName = "massflash";

    # Assuming wifi device name
    # TODO: fix to make agnositic like flash0
    wireless = {
      enable = true;
      userControlled.enable = true;
    };

    interfaces.wlp3s0.useDHCP = true;
  };

  # root user doesnt need credentials for massflash liveCD
  users.extraUsers.root.password = lib.mkForce "";

  # we set the hashedPassword in _common so just ensure that this is actually null
  users.extraUsers.root.hashedPassword = lib.mkForce null;

  security.sudo.wheelNeedsPassword = false;

  environment = {
    systemPackages = with pkgs; [
      expect
      git
      kea
      inputs.self.packages.${pkgs.system}.massflash
      unixtools.ping
      tmux
      vim
    ] ++ [ addtobr ];

    etc."massflash.conf" = {
      text = ''
        state_dir="/persist/massflash"
      '';
    };
  };

  services = {
    openssh = {
      enable = true;
    };
    kea = {
      dhcp4 = {
        enable = true;
        configFile = pkgs.writeText "keaconfig" ''
          {
                "Dhcp4": {
                "interfaces-config": {
                    "interfaces": [ "flash0.503" ],
                    "dhcp-socket-type": "raw"
                },
                "valid-lifetime": 600,
                "renew-timer": 300,
                "rebind-timer": 400,
                "subnet4": [{
                   "subnet": "192.168.252.0/22",
                   "pools": [ { "pool": "192.168.252.50-192.168.254.254" } ]
                }],
                "loggers": [{
                    "name": "*",
                    "severity": "DEBUG"
                }],
                "hooks-libraries": [{
                          "library": "${pkgs.kea}/lib/kea/hooks/libdhcp_run_script.so",
                          "parameters": {
                              "name": "${inputs.self.packages.${pkgs.system}.massflash}/bin/massflash",
                              "sync": false
                        }
                }]
                }
          }
        '';
      };
    };
  };

}

