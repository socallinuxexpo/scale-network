inputs:
inputs.nixpkgs.lib.genAttrs
  [
    "x86_64-linux"
    "aarch64-linux"
  ]
  (
    system:
    let
      pkgs = inputs.self.legacyPackages.${system};

      scalePython = [
        (pkgs.python3.withPackages (
          ps: with ps; [
            pytest
            pylint
            ipdb
          ]
        ))
      ];

      global = with pkgs; [
        bash
        curl
        fish
        git
        jq
        kermit
        screen
        glibcLocales
      ];

      openwrtSub = with pkgs; [
        expect
        gomplate
        magic-wormhole
        tftp-hpa
        nettools
        unixtools.ping
        iperf3
        ncurses
        ncurses.dev
        pkg-config
        gcc
        stdenv
        scale-network.serverspec
      ];

      networkSub = with pkgs; [
        perl
        perlPackages.libnet
        perlPackages.Expect
        perlPackages.TermReadKey
        perlPackages.NetSFTPForeign
        scale-network.perlNetArp
        scale-network.perlNetInterface
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
  )
