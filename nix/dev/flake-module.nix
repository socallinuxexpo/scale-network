{ inputs, ...}:

{
  perSystem = { pkgs, ... }:
    let
      scale_python = pkgs.python3.withPackages (p: with p ; [ pytest pylint ipdb ]);

      # Trying to keep these pkg sets separate for later
      global = with pkgs; [
        bash
        curl
        git
        jq
        kermit
        screen
        glibcLocales
        (pkgs.python3.withPackages (p: with p ; [ pytest pylint ipdb ]))
      ];
      openwrt_sub = with pkgs; [
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
        inputs.self.packages.${pkgs.system}.serverspec
      ];
      network_sub = with pkgs; [ perl ghostscript ];
    in
    {
      devShells.default = pkgs.mkShell {
        packages = global
          ++ openwrt_sub
          ++ network_sub;
      };
    };
}
