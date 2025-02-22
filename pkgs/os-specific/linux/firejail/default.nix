{ lib
, stdenv
, fetchFromGitHub
, fetchpatch
, pkg-config
, glibc
, libapparmor
, which
, xdg-dbus-proxy
, nixosTests
}:

stdenv.mkDerivation rec {
  pname = "firejail";
  version = "0.9.68rc1";

  src = fetchFromGitHub {
    owner = "netblue30";
    repo = "firejail";
    rev = version;
    sha256 = "sha256-AkPU1G/EqbXz6wXDjaDwutBXcmHFM99f4fZA7EsE8Sg=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    glibc
    libapparmor
    which
  ];

  configureFlags = [
    "--enable-apparmor"
  ];

  patches = [
    # Adds the /nix directory when using an overlay.
    # Required to run any programs under this mode.
    ./mount-nix-dir-on-overlay.patch
    # By default fbuilder hardcodes the firejail binary to the install path.
    # On NixOS the firejail binary is a setuid wrapper available in $PATH.
    ./fbuilder-call-firejail-on-path.patch
    # Firejail hardcodes some paths that need to be adjusted on NixOS
    ./nix-paths.patch
  ];

  prePatch = ''
    # Fix the path to 'xdg-dbus-proxy' hardcoded in the 'common.h' file
    substituteInPlace src/include/common.h \
      --replace '/usr/bin/xdg-dbus-proxy' '${xdg-dbus-proxy}/bin/xdg-dbus-proxy'
  '';

  preConfigure = ''
    sed -e 's@/bin/bash@${stdenv.shell}@g' -i $( grep -lr /bin/bash .)
    sed -e 's@/bin/sh@${stdenv.shell}@g' -i $( grep -lr /bin/sh .)
    sed -e "s@/bin/cat@$(which cat)@g" -i $( grep -lr /bin/cat .)
    sed -e "s@/bin/cp@$(which cp)@g" -i $( grep -lr /bin/cp .)
    sed -e "s@/bin/rm@$(which rm)@g" -i $( grep -lr /bin/rm .)
    sed -e "s@/bin/ls@$(which ls)@g" -i $( grep -lr /bin/ls .)
    sed -e "s@/bin/mv@$(which mv)@g" -i $( grep -lr /bin/mv .)
    sed -e "s@__nix_libc_lib_path__@${lib.getLib glibc}/lib@g" -i $( grep -lr __nix_libc_lib_path__ .)
    sed -e "s@__nix_libapparmor_lib_path__@${lib.getLib libapparmor}/lib@g" -i $( grep -lr __nix_libapparmor_lib_path__ .)
  '';

  preBuild = ''
    sed -e "s@/etc/@$out/etc/@g" -e "/chmod u+s/d" -i Makefile
  '';

  # The profile files provided with the firejail distribution include `.local`
  # profile files using relative paths. The way firejail works when it comes to
  # handling includes is by looking target files up in `~/.config/firejail`
  # first, and then trying `SYSCONFDIR`. The latter normally points to
  # `/etc/filejail`, but in the case of nixos points to the nix store. This
  # makes it effectively impossible to place any profile files in
  # `/etc/firejail`.
  #
  # The workaround applied below is by creating a set of `.local` files which
  # only contain respective includes to `/etc/firejail`. This way
  # `~/.config/firejail` still takes precedence, but `/etc/firejail` will also
  # be searched in second order. This replicates the behaviour from
  # non-nixos platforms.
  #
  # See https://github.com/netblue30/firejail/blob/e4cb6b42743ad18bd11d07fd32b51e8576239318/src/firejail/profile.c#L68-L83
  # for the profile file lookup implementation.
  postInstall = ''
    for local in $(grep -Eh '^include.*local$' $out/etc/firejail/*{.inc,.profile} | awk '{print $2}' | sort | uniq)
    do
      echo "include /etc/firejail/$local" >$out/etc/firejail/$local
    done
  '';

  # At high parallelism, the build sometimes fails with:
  # bash: src/fsec-optimize/fsec-optimize: No such file or directory
  enableParallelBuilding = false;

  passthru.tests = nixosTests.firejail;

  meta = {
    description = "Namespace-based sandboxing tool for Linux";
    license = lib.licenses.gpl2Plus;
    maintainers = [ lib.maintainers.raskin ];
    platforms = lib.platforms.linux;
    homepage = "https://firejail.wordpress.com/";
  };
}
