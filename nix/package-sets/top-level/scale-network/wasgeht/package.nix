{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  unixtools,
  rrdtool,
  go_1_25,
}:

buildGoModule.override { go = go_1_25; } rec {
  pname = "wasgeht";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "kylerisse";
    repo = "wasgeht";
    rev = "refs/tags/${version}";
    hash = "sha256-Yi+35tCe8mnZqs87rBGu8eGhMEPGdvieq0j/6DIh9Ho=";
  };

  strictDeps = true;

  vendorHash = "sha256-EGGsQUqGzbQvyO6nymkG/FR/9IZXAUcmGriRFuwNPMc=";

  ldflags = [
    "-s"
    "-w"
  ];

  buildInputs = [
    unixtools.ping
    makeWrapper
    rrdtool
  ];

  checkPhase = ''
    go test --short --race -v ./...
  '';

  postFixup = ''
    wrapProgram $out/bin/wasgehtd --set PATH ${
      lib.makeBinPath [
        rrdtool
        unixtools.ping
      ]
    }
  '';

  meta = with lib; {
    description = "90s style monitoring";
    homepage = "https://github.com/kylerisse/wasgeht";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    mainProgram = "wasgehtd";
  };
}
