name="cmake"
version="3.29.6"
release="1"
license="BSD-3-Clause"
maintainer="Hydra Linux Team"

source=(
  "https://cmake.org/files/v3.29/cmake-${version}.tar.gz"
)

sha256sums=(
  "b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b"
)

depends=()
build_depends=("openssl" "libuv" "curl")

prepare() {
  tar xf "${srcdir}/cmake-${version}.tar.gz"
}

build() {
  cd "${srcdir}/cmake-${version}"
  ./bootstrap --prefix=/usr
  make -j$(nproc)
}

install() {
  cd "${srcdir}/cmake-${version}"
  make DESTDIR="${pkgdir}" install
}
