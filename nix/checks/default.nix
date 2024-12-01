inputs:
let
  # inherits
  inherit (inputs.nixpkgs)
    lib
    ;

  inherit (lib.attrsets)
    genAttrs
    ;

  inherit (lib.fileset)
    toSource
    unions
    ;

  # sources

  # Used for derivations where facts is the primary directory.
  factsSrc = toSource {
    root = ../..;
    fileset = unions [
      ../../facts
      ../../switch-configuration
    ];
  };

  # Used for derivations where switch-configuration is the primary directory.
  switchConfigurationSrc = toSource {
    root = ../..;
    fileset = unions [
      ../../facts
      ../../switch-configuration
    ];
  };

  # Used for derivations where openwrt is the primary directory.
  openwrtSrc = toSource {
    root = ../..;
    fileset = unions [
      ../../facts
      ../../openwrt
      ../../tests
    ];
  };
in
genAttrs
  [
    "x86_64-linux"
    "aarch64-linux"
  ]
  (
    system:
    let
      pkgs = inputs.self.legacyPackages.${system};
    in
    {
      core = pkgs.testers.runNixOSTest (import ./core.nix { inherit inputs; });
      loghost = pkgs.testers.runNixOSTest ./loghost.nix;

      pytest-facts =
        let
          testPython = (
            pkgs.python3.withPackages (
              pythonPackages: with pythonPackages; [
                pylint
                pytest
                jinja2
              ]
            )
          );
        in
        (pkgs.runCommand "pytest-facts"
          {
            src = factsSrc;
            buildInputs = [ testPython ];
          }
          ''
            cd $src/facts
            pylint --persistent n *.py
            pytest -vv -p no:cacheprovider
            touch $out
          ''
        );

      duplicates-facts = (
        pkgs.runCommand "duplicates-facts"
          {
            src = factsSrc;
            buildInputs = [ pkgs.fish ];
          }
          ''
            cd $src/facts
            fish --no-config test_duplicates.fish
            touch $out
          ''
      );

      perl-switches = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "perl-switches";
        version = "0.1.0";

        src = switchConfigurationSrc;

        nativeBuildInputs = with pkgs; [
          gnumake
          perl
        ];

        buildPhase = ''
          cd switch-configuration
          make .lint
          make .build-switch-configs
        '';

        installPhase = ''
          touch $out
        '';
      });

      openwrt-golden = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "openwrt-golden";
        version = "0.1.0";

        src = openwrtSrc;

        buildInputs = [
          pkgs.diffutils
          pkgs.gomplate
        ];

        buildPhase = ''
          cd tests/unit/openwrt
          mkdir -p $out/tmp/ar71xx
        '';

        installPhase = ''
          ./test.sh -t ar71xx -o $out
        '';
      });

      formatting = inputs.self.formatterModule.${system}.config.build.check inputs.self;

    }
  )
