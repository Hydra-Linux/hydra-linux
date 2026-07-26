name="firefox"
version="129.0"
release="1"
license="MPL-2.0"
maintainer="Hydra Linux Team"

source=(
  "https://archive.mozilla.org/pub/firefox/releases/${version}/source/firefox-${version}.source.tar.xz"
)

sha256sums=(
  "0000000000000000000000000000000000000000000000000000000000000000"
)

depends=("glibc" "pango" "cairo" "libx11" "libxcb" "gtk3" "dbus" "nss" "nspr" "zlib" "bzip2" "libvpx" "icu")
build_depends=("rust" "clang" "llvm" "cargo" "nodejs" "make" "pkgconf" "python" "yasm" "mesa")

build() {
  cd "${srcdir}/firefox-${version}"
  ./mach configure --prefix=/usr
  ./mach build
}

install() {
  cd "${srcdir}/firefox-${version}"
  DESTDIR="${pkgdir}" ./mach install
}
