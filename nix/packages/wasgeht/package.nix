{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  unixtools,
  rrdtool,
}:

buildGoModule rec {
  pname = "wasgeht";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "kylerisse";
    repo = "wasgeht";
    rev = "refs/tags/${version}";
    hash = "sha256-+KLjVt5WKcngFCGyQTIoNJVKprn/7fyAiNLkxW6onN0=";
  };

  strictDeps = true;

  vendorHash = "sha256-0HDZ3llIgLMxRLNei93XrcYliBzjajU6ZPllo3/IZVY=";

  ldflags = [
    "-s"
    "-w"
  ];

  buildInputs = [
    unixtools.ping
    makeWrapper
    rrdtool
  ];

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
