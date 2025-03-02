{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  iputils,
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

  vendorHash = "sha256-0HDZ3llIgLMxRLNei93XrcYliBzjajU6ZPllo3/IZVY=";

  ldflags = [
    "-s"
    "-w"
  ];

  buildInputs = [
    iputils
    makeWrapper
    rrdtool
  ];

  propogatedBuildInputs = [
    iputils
    rrdtool
  ];

  postFixup = ''
    wrapProgram $out/bin/wasgehtd --set PATH ${
      lib.makeBinPath [
        rrdtool
        iputils
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
