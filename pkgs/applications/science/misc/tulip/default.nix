{ fetchurl, lib, stdenv, libxml2, freetype, libGLU, libGL, glew, qt4
, cmake, makeWrapper, libjpeg, python2 }:

let version = "5.2.1"; in
stdenv.mkDerivation rec {
  pname = "tulip";
  inherit version;

  src = fetchurl {
    url = "mirror://sourceforge/auber/${pname}-${version}_src.tar.gz";
    sha256 = "0bqmqy6sri87a8xv5xf7ffaq5zin4hiaa13g0l64b84i7yckfwky";
  };

  buildInputs = [ libxml2 freetype glew libGLU libGL qt4 libjpeg python2 ];

  nativeBuildInputs = [ cmake makeWrapper ];

  # FIXME: "make check" needs Docbook's DTD 4.4, among other things.
  doCheck = false;

  meta = {
    description = "A visualization framework for the analysis and visualization of relational data";

    longDescription =
      '' Tulip is an information visualization framework dedicated to the
         analysis and visualization of relational data.  Tulip aims to
         provide the developer with a complete library, supporting the design
         of interactive information visualization applications for relational
         data that can be tailored to the problems he or she is addressing.
      '';

    homepage = "http://tulip.labri.fr/";

    license = lib.licenses.gpl3Plus;

    maintainers = [ ];
    platforms = lib.platforms.gnu ++ lib.platforms.linux;  # arbitrary choice
  };
}
