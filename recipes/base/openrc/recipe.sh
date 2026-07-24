name="openrc"
version="0.55"
release="1"
license="BSD-2-Clause"
maintainer="Hydra Linux Team"

source=(
  "https://github.com/OpenRC/openrc/archive/${version}.tar.gz"
)

sha256sums=(
  "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b"
)

depends=("glibc")
build_depends=("meson" "ninja")

prepare() {
  tar xf "${srcdir}/${version}.tar.gz"
  mv "openrc-${version}" "openrc-${version}"
}

build() {
  cd "${srcdir}/openrc-${version}"
  meson setup build
  ninja -C build
}

install() {
  cd "${srcdir}/openrc-${version}"
  DESTDIR="${pkgdir}" ninja -C build install
}

check() {
  cd "${srcdir}/openrc-${version}"
  ninja -C build test
}
