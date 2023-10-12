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
      ansible_sub = [
        pkgs.ansible
        pkgs.ansible-lint
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
      ];
      network_sub = [ pkgs.perl ];
    in
    {
      devShells.default = pkgs.mkShell {
        packages = global
          ++ ansible_sub
          ++ openwrt_sub
          ++ network_sub;
      };
    };
}
