{ withSystem, inputs, ... }:

{
  flake.checks.x86_64-linux = withSystem "x86_64-linux" ({ pkgs, ... }: {
    core = pkgs.testers.runNixOSTest (import ./core.nix { inherit inputs; });
    loghost = pkgs.testers.runNixOSTest ./loghost.nix;
  });

  perSystem = { pkgs, lib, ... }: {
    checks = {
      # python tests for the data found in facts
      # disabling persistence and cache for py utils to avoid warnings
      # since caching is taken care of by nix
      pytest-facts = (pkgs.runCommand "pytest-facts" { } ''
        cp -r --no-preserve=mode ${pkgs.lib.cleanSource inputs.self}/* .
        cd facts
        ${pkgs.python3Packages.pylint}/bin/pylint --persistent n *.py
        ${pkgs.python3Packages.pytest}/bin/pytest -vv -p no:cacheprovider
        touch $out
      '');

      perl-switches = (pkgs.runCommand "perl-switches"
        {
          buildInputs = [ pkgs.gnumake pkgs.perl ];
        } ''
        cp -r --no-preserve=mode ${lib.cleanSource inputs.self}/* .
        cd switch-configuration
        make .lint
        make .build-switch-configs 
        touch $out
      '');
      openwrt-golden = pkgs.runCommand "openwrt-golden"
        {
          buildInputs = [ pkgs.diffutils pkgs.gomplate ];
        } ''
        cp -r --no-preserve=mode ${pkgs.lib.cleanSource inputs.self}/* .
        cd tests/unit/openwrt
        mkdir -p $out/tmp/ar71xx
        ${pkgs.bash}/bin/bash test.sh -t ar71xx -o $out
      '';

    };
  };
}
