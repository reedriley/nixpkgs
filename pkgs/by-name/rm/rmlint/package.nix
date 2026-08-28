{
  lib,
  stdenv,
  cairo,
  elfutils,
  fetchFromGitHub,
  glib,
  gobject-introspection,
  gtksourceview3,
  json-glib,
  makeWrapper,
  pango,
  pkg-config,
  polkit,
  python3,
  scons,
  util-linux,
  wrapGAppsHook3,
  withGui ? false,
}:

assert withGui -> !stdenv.hostPlatform.isDarwin;

stdenv.mkDerivation (finalAttrs: {
  pname = "rmlint";
  version = "2.10.3";

  src = fetchFromGitHub {
    owner = "sahib";
    repo = "rmlint";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Q5nonICxyWTAu1gHWaqWi1pq6yMD5mzMwnwQ8lOCY4A=";
  };

  patches = [
    # pass through NIX_* environment variables to scons.
    ./scons-nix-env.patch
    ./bcachefs.patch
  ];

  nativeBuildInputs = [
    pkg-config
    python3.pkgs.sphinx
    scons
  ]
  ++ lib.optionals withGui [
    makeWrapper
    wrapGAppsHook3
    gobject-introspection
  ];

  buildInputs = [
    glib
    json-glib
    util-linux
  ]
  ++ lib.optionals withGui [
    cairo
    gtksourceview3
    pango
    polkit
    python3
    python3.pkgs.pygobject3
  ]
  ++ lib.optionals (lib.meta.availableOn stdenv.hostPlatform elfutils) [
    elfutils
  ];

  prePatch = ''
    # remove sources of nondeterminism
    substituteInPlace lib/cmdline.c \
      --replace "__DATE__" "\"Jan  1 1970\"" \
      --replace "__TIME__" "\"00:00:00\""
  '';

  # Otherwise tries to access /usr.
  prefixKey = "--prefix=";

  sconsFlags = lib.optionals (!withGui) [ "--without-gui" ];

  # in GUI mode, this shells out to itself, and tries to import python modules
  postInstall = lib.optionalString withGui ''
    gappsWrapperArgs+=(--prefix PATH : "$out/bin")
    gappsWrapperArgs+=(--prefix PYTHONPATH : "$(toPythonPath $out):$(toPythonPath ${python3.pkgs.pygobject3}):$(toPythonPath ${python3.pkgs.pycairo})")
  '';

  meta = {
    description = "Extremely fast tool to remove duplicates and other lint from your filesystem";
    homepage = "https://rmlint.readthedocs.org";
    platforms = lib.platforms.unix;
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [
      aaschmid
      koral
    ];
    mainProgram = "rmlint";
  };
})
