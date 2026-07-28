name="libcap"
version="2.70"
release="1"
license="BSD-3-Clause"
maintainer="Hydra Linux Team"

source=(
  "https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-${version}.tar.xz"
)

sha256sums=(
  "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0ab"
)

depends=()
build_depends=()

prepare() {
  tar xf "${srcdir}/libcap-${version}.tar.xz"
}

build() {
  cd "${srcdir}/libcap-${version}"
  make -j$(nproc)
}

install() {
  cd "${srcdir}/libcap-${version}"
  make DESTDIR="${pkgdir}" prefix=/usr install
}
