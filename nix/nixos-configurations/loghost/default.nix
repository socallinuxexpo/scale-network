{
  release = "2405";

  modules =
    {
      inputs,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.microvm.nixosModules.microvm
      ];

      config = {
        nixpkgs.hostPlatform = "x86_64-linux";

        scale-network = {
          base.enable = true;
          services.prometheus.enable = true;
          services.ssh4vms.enable = true;
          timeServers.enable = true;

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

        boot.kernelParams = [ "console=ttyS0" ];

        networking = {
          firewall.allowedTCPPorts = [ 514 ];
        };

        # TODO: How to handle sudo esculation
        security.sudo.wheelNeedsPassword = false;

        environment.systemPackages = with pkgs; [
          rsyslog
          vim
          git
        ];

        # Easy test of the service using logger
        # logger -n 127.0.0.1 -P 514 --tcp "simple test"
        # cat /var/log/rsyslog/<hostname>/root.log
        services.rsyslogd = {
          enable = true;
          defaultConfig = ''
            module(load="imtcp")
            input(type="imtcp" port="514")

            $template RemoteLogs,"/var/log/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log"
            *.* ?RemoteLogs
            & ~
          '';
        };

      };
    };
}
