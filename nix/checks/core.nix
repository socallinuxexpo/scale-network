{ inputs, lib }:
let
  chomp = "103";
  prefix = "2001:470:f026:${chomp}";
  routerAddr = {
    ipv6 = "${prefix}::1";
    ipv4 = "10.0.3.1";
  };
  coremasterAddr = {
    ipv6 = "${prefix}::20";
    ipv4 = "10.0.3.20";
  };

  inherit (lib.modules)
    mkForce
    ;
in
{
  name = "core";

  nodes = {
    # temporary router since we do not have the junipers for ipv6 router advertisement
    router =
      { ... }:
      {
        virtualisation.vlans = [ 1 ];
        systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";
        # since this is a router we need to set enable ipv6 forwarding or radvd will complain
        boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = true;
        networking = {
          useDHCP = false;
          useNetworkd = true;
        };
        systemd.network = {
          enable = true;
          networks = {
            "01-eth1" = {
              name = "eth1";
              enable = true;
              networkConfig = {
                DHCP = "no";
                IPv6AcceptRA = false;
                IPv6PrivacyExtensions = false;
              };
              address = [
                "${routerAddr.ipv6}/64"
                "${routerAddr.ipv4}/24"
              ];
              ipv6AcceptRAConfig = {
                UseAutonomousPrefix = true;
                #DHCPv6Client = "always";
                #UseDNS = true;
              };
            };
          };
        };
        services.radvd.enable = true;
        services.radvd.config = ''
          interface eth1 {
            AdvSendAdvert on;
            # M Flag
            AdvManagedFlag on;
            # O Flag
            AdvOtherConfigFlag on;
            # ULA prefix (RFC 4193).
            prefix ${prefix}::/64 {
              AdvOnLink on;
            };
          };
        '';
      };

    # node must match hostname for testScript to find it below
    coremaster =
      { lib, ... }:
      {
        _module.args = {
          inherit inputs;
        };
        imports = [
          ../nixos-configurations/core-master/configuration.nix
          inputs.self.nixosModules.default
        ];

        scale-network.facts = lib.mkForce {
          ipv4 = "${coremasterAddr.ipv4}/24";
          ipv6 = "${coremasterAddr.ipv6}/64";
          eth = "eth1";
        };

        virtualisation.vlans = [ 1 ];
        systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";
        networking.useDHCP = false;
        systemd.network = {
          enable = true;
          networks = {
            # Override the physical interface config
            "10-lan" = lib.mkForce {
              name = "eth1";
              enable = true;
              address = [
                "${coremasterAddr.ipv6}/64"
                "${coremasterAddr.ipv4}/24"
              ];
              gateway = [ "${routerAddr.ipv4}" ];
            };
          };
        };
      };

    client1 =
      { pkgs, ... }:
      {
        virtualisation.vlans = [ 1 ];
        systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";
        networking = {
          useNetworkd = true;
          useDHCP = false;
          firewall.enable = false;
        };
        systemd.network = {
          enable = true;
          networks = {
            "01-eth1" = {
              name = "eth1";
              enable = true;
              networkConfig = {
                DHCP = "yes";
                IPv6AcceptRA = true;
                IPv6PrivacyExtensions = false;
                UseDomains = true; # so dhcp client uses search domain
              };
              ipv6AcceptRAConfig = {
                UseAutonomousPrefix = false;
                #DHCPv6Client = "always";
                #UseDNS = true;
              };
            };
          };
        };
        environment = {
          systemPackages = with pkgs; [
            ldns
            dig
          ];
        };
      };
  };

  testScript =
    { nodes, ... }:
    let
    in
    # TODO: do this for all zones
    #scaleZone = "${nodes.coremaster.services.bind.zones."scale.lan.".file}";
    #coremaster.succeed("named-checkzone scale.lan ${scaleZone}")
    ''
      start_all()
      router.wait_for_unit("radvd.service")
      coremaster.wait_for_unit("ntpd.service")
      coremaster.wait_for_unit("bind.service")
      coremaster.succeed("kea-dhcp4 -t /etc/kea/dhcp4-server.conf")
      coremaster.succeed("named-checkconf ${nodes.coremaster.config.services.bind.configFile}")
      client1.wait_until_succeeds("ping -c 5 ${coremasterAddr.ipv4}")
      client1.wait_until_succeeds("ip route show | grep default | grep -w ${routerAddr.ipv4}")
      # ensure that we got the correct prefix and suffix on dhcpv6
      client1.wait_until_succeeds("ip addr show dev eth1 | grep inet6 | grep ${chomp}:d8c")
      # Have to wrap drill since retcode isnt necessarily 1 on query failure
      client1.wait_until_succeeds("test ! -z \"$(drill -Q -z scale.lan SOA)\"")
      client1.wait_until_succeeds("test ! -z \"$(drill -Q -z coreexpo.scale.lan A)\"")
      client1.wait_until_succeeds("test ! -z \"$(drill -Q -z coreexpo.scale.lan AAAA)\"")
      client1.wait_until_succeeds("test ! -z \"$(drill -Q -z -x ${coremasterAddr.ipv4})\"")
      client1.succeed("test ! -z \"$(systemd-resolve -4 --search=true coreexpo)\"")
      client1.succeed("test ! -z \"$(systemd-resolve -6 --search=true coreexpo)\"")
    '';

  interactive.nodes =
    let
      interactiveDefaults = hostPort: {
        services.openssh.enable = true;
        services.openssh.settings.PermitRootLogin = mkForce "yes";
        systemd.network.networks."01-eth0" = {
          name = "eth0";
          enable = true;
          networkConfig.DHCP = "yes";
        };
        virtualisation.forwardPorts = [
          {
            from = "host";
            host.port = hostPort;
            guest.port = 22;
          }
        ];
      };
    in
    {
      router = interactiveDefaults 2222;
      coremaster = interactiveDefaults 2223;
      client1 = interactiveDefaults 2224;
    };
}
