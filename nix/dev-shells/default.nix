inputs:
let

  inherit (inputs.nixpkgs-lib)
    lib
    ;

  inherit (lib.attrsets)
    mapAttrs
    ;

  inherit (lib.trivial)
    const
    ;

in
mapAttrs (const (
  pkgs:
  let

    scalePython = [
      (pkgs.python3.withPackages (
        ps: with ps; [
          pytest
          pylint
          ipdb
          jinja2
          pandas
        ]
      ))
    ];

    global = with pkgs; [
      bash
      curl
      git
      jq
      tio
      screen
      glibcLocales
      scale-network.mac2eui64
    ];

    openwrtSub = with pkgs; [
      dnsmasq
      expect
      gomplate
      magic-wormhole
      tftp-hpa
      nettools
      unixtools.ping
      iperf3
      scale-network.rperf
      ncurses
      ncurses.dev
      pkg-config
      gcc
      stdenv
      scale-network.make-dhcpd
      scale-network.serverspec
    ];

    networkSub = with pkgs; [
      perl
      perlPackages.libnet
      perlPackages.Expect
      perlPackages.TermReadKey
      perlPackages.NetSFTPForeign
      scale-network.perl-net-arp
      scale-network.perl-net-interface
      scale-network.perl-net-ping
      ghostscript
    ];
  in
  {
    scalePython = pkgs.mkShellNoCC {
      packages = scalePython;
    };

    global = pkgs.mkShellNoCC {
      packages = global;
    };

    openwrtSub = pkgs.mkShellNoCC {
      packages = openwrtSub;
    };

    networkSub = pkgs.mkShellNoCC {
      packages = networkSub;
    };

    default = pkgs.mkShellNoCC {
      packages = (scalePython ++ global ++ openwrtSub ++ networkSub);
    };
  }
)) inputs.self.legacyPackages
