name="wireguard-tools"
version="1.0.20210914"
release="1"
license="GPL-2.0-only"
maintainer="Hydra Linux Team"

source=(
  "https://git.zx2c4.com/wireguard-tools/snapshot/wireguard-tools-${version}.tar.xz"
)

sha256sums=(
  "e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1"
)

depends=("glibc")
build_depends=("make")

prepare() {
  tar xf "${srcdir}/wireguard-tools-${version}.tar.xz"
}

build() {
  cd "${srcdir}/wireguard-tools-${version}/src"
  make
}

install() {
  cd "${srcdir}/wireguard-tools-${version}/src"
  make DESTDIR="${pkgdir}" install
}

check() {
  cd "${srcdir}/wireguard-tools-${version}/src"
  make -j$(nproc) check
}
