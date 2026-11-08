{
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "rperf";
  version = "0.1.23";
  checkType = "debug";

  src = fetchFromGitHub {
    owner = "mfreeman451";
    repo = "rperf";
    rev = "72a02ce0142e7d4da68126ed41522191785824da";
    hash = "sha256-gTdp7LpPwWi6hUu62hMPYbdaLCdQNWPl/VxIrE91vww=";
  };

  cargoHash = "sha256-itstgUiASkSlPFbMmKRIEVebApYBDDQT8GRghbeheLA=";

  meta = {
    description = "A Rust implementation of the iperf3 tool.";
    homepage = "https://github.com/mfreeman451/rperf";
  };
}
