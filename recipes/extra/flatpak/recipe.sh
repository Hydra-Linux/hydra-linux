name="flatpak"
version="1.15.9"
release="1"
license="LGPL-2.1-only"
maintainer="Hydra Linux Team"

source=(
  "https://github.com/flatpak/flatpak/releases/download/${version}/flatpak-${version}.tar.xz"
)

sha256sums=(
  "0000000000000000000000000000000000000000000000000000000000000000"
)

depends=("glibc" "glib2" "ostree" "libxml2" "polkit" "bubblewrap" "dconf" "gpgme" "curl" "zlib" "libseccomp" "libsoup3" "json-glib")
build_depends=("meson" "ninja" "pkgconf")

build() {
  cd "${srcdir}/flatpak-${version}"
  meson setup build --prefix=/usr
  ninja -C build
}

install() {
  cd "${srcdir}/flatpak-${version}"
  DESTDIR="${pkgdir}" ninja -C build install
}
