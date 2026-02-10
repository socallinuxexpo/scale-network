{
  lib,
  python3,
  runCommand,
}:
let

  inherit (lib.fileset)
    toSource
    unions
    ;

  root = ../../../..;

in
runCommand "pytest-facts"
  {
    src = toSource {
      inherit root;
      fileset = unions [
        (root + "/facts")
        (root + "/switch-configuration")
      ];
    };

    buildInputs = [
      (python3.withPackages (ps: [
        ps.pylint
        ps.pytest
        ps.jinja2
        ps.pandas
      ]))
    ];
  }

  ''
    cd $src/facts
    pylint --persistent n *.py
    pytest -vv -p no:cacheprovider
    touch $out
  ''
