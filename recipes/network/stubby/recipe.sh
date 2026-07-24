name="stubby"
version="0.4.3"
release="1"
license="BSD-3-Clause"
maintainer="Hydra Linux Team"

source=(
  "https://github.com/getdnsapi/stubby/archive/v${version}.tar.gz"
)

sha256sums=(
  "d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0"
)

depends=("glibc" "libyaml" "getdns")
build_depends=("meson" "ninja")

prepare() {
  tar xf "${srcdir}/v${version}.tar.gz"
}

build() {
  cd "${srcdir}/stubby-${version}"
  meson setup build \
    -Dprefix=/usr \
    -Dbuildtype=release
  ninja -C build
}

install() {
  cd "${srcdir}/stubby-${version}"
  DESTDIR="${pkgdir}" ninja -C build install
}

check() {
  cd "${srcdir}/stubby-${version}"
  ninja -C build test
}
