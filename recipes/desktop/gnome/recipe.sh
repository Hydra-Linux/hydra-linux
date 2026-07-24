name="gnome"
version="46"
release="1"
license="GPL-2.0-only"
maintainer="Hydra Linux Team"

source=(
  "https://download.gnome.org/core/46/gnome-${version}.tar.xz"
)

sha256sums=(
  "e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5"
)

depends=("gtk4" "mutter" "gnome-shell" "gdm" "glibc" "pango" "gdk-pixbuf" "gsettings-desktop-schemas")
build_depends=("meson" "ninja")

prepare() {
  tar xf "${srcdir}/gnome-${version}.tar.xz"
}

build() {
  cd "${srcdir}/gnome-${version}"
  meson setup build \
    -Dprefix=/usr \
    -Dbuildtype=release \
    -Dsystemd=false \
    -Dopenrc=true
  ninja -C build
}

install() {
  cd "${srcdir}/gnome-${version}"
  DESTDIR="${pkgdir}" ninja -C build install
}

check() {
  cd "${srcdir}/gnome-${version}"
  ninja -C build test
}
