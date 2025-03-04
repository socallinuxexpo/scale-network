{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  unixtools,
  rrdtool,
}:

buildGoModule {
  pname = "wasgeht";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "kylerisse";
    repo = "wasgeht";
    rev = "refs/tags/0.1.2";
    hash = "sha256-Sqfi3Yo6ZUNZLNy8g+P85Q5JwMUgiGYuQZxVcQOUDLM=";
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
