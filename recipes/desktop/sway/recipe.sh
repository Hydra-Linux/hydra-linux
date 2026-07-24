name="sway"
version="1.9"
release="1"
license="MIT"
maintainer="Hydra Linux Team"

source=(
  "https://github.com/swaywm/sway/archive/${version}.tar.gz"
)

sha256sums=(
  "a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7"
)

depends=("wlroots" "wayland" "glibc" "pcre2" "json-c" "libinput" "libxkbcommon" "pango" "cairo" "gdk-pixbuf")
build_depends=("meson" "ninja" "scdoc")

prepare() {
  tar xf "${srcdir}/${version}.tar.gz"
  mv "sway-${version}" "sway-${version}"
}

build() {
  cd "${srcdir}/sway-${version}"
  meson setup build \
    -Dprefix=/usr \
    -Dbuildtype=release \
    -Ddefault-wallpaper=true \
    -Dtray=enabled \
    -Dgdk-pixbuf=enabled
  ninja -C build
}

install() {
  cd "${srcdir}/sway-${version}"
  DESTDIR="${pkgdir}" ninja -C build install
}

check() {
  cd "${srcdir}/sway-${version}"
  ninja -C build test
}
