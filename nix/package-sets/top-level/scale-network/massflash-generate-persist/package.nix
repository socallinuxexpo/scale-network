{
  python3,
  gh,
}:

python3.pkgs.callPackage (
  {
    buildPythonApplication,
    flit-core,
    pydantic,
    typer,
  }:
  buildPythonApplication {
    pname = "massflash-generate-persist";
    version = "1.0";

    pyproject = true;
    build-system = [ flit-core ];

    dependencies = [
      pydantic
      typer
      gh
    ];

    src = ./src;
  }
) { }
