inputs:
inputs.self.library.defaultSystems (
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
