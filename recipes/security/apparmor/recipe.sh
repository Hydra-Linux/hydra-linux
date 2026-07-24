name="apparmor"
version="4.0"
release="1"
license="GPL-2.0-only"
maintainer="Hydra Linux Team"

source=(
  "https://gitlab.com/apparmor/apparmor/-/archive/v${version}/apparmor-v${version}.tar.gz"
)

sha256sums=(
  "b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4"
)

depends=("glibc" "glib" "pcre2" "python")
build_depends=("meson" "ninja")

prepare() {
  tar xf "${srcdir}/apparmor-v${version}.tar.gz"
}

build() {
  cd "${srcdir}/apparmor-v${version}"
  meson setup build \
    -Dprefix=/usr \
    -Dbuildtype=release
  ninja -C build
}

install() {
  cd "${srcdir}/apparmor-v${version}"
  DESTDIR="${pkgdir}" ninja -C build install
}

check() {
  cd "${srcdir}/apparmor-v${version}"
  ninja -C build test
}
