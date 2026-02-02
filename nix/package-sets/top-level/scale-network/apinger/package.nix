{
  autoreconfHook,
  bison,
  fetchFromGitHub,
  flex,
  libxslt,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "apinger";
  version = builtins.substring 0 9 finalAttrs.src.rev;

  src = fetchFromGitHub {
    owner = "Jajcus";
    repo = "apinger";
    rev = "78eb328721ba1a10571c19df95acddcb5f0c17c8";
    hash = "sha256-I1voKq3q3r88r9tiq+YfKwrwVuOJa8NkD9o9nT2cRh4=";
  };

  patches = [
    ./run-as-user.patch
    ./no-docs.patch
    ./poll.patch
    ./gcc10.patch
  ];

  nativeBuildInputs = [
    autoreconfHook
    bison
    flex
    libxslt
  ];

  meta.mainProgram = "apinger";
})
