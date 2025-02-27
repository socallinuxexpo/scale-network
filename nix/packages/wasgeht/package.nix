{
  lib,
  buildGoModule,
  fetchFromGitHub,
  rrdtool,
  unixtools,
}:

buildGoModule {
  pname = "wasgeht";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "kylerisse";
    repo = "wasgeht";
    rev = "refs/tags/0.1.1";
    hash = "sha256-NTASU/vXqr7zwYAXGSz2UD9DcDIcsASH0nduytdJ6J8=";
  };

  vendorHash = "sha256-0HDZ3llIgLMxRLNei93XrcYliBzjajU6ZPllo3/IZVY=";

  ldflags = [
    "-s"
    "-w"
  ];

  buildInputs = [
    rrdtool
    unixtools.ping
  ];

  meta = with lib; {
    description = "90s style monitoring";
    homepage = "https://github.com/kylerisse/wasgeht";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    mainProgram = "wasgeht";
  };
}
