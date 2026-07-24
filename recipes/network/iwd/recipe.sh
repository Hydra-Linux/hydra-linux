name="iwd"
version="2.20"
release="1"
license="LGPL-2.1-only"
maintainer="Hydra Linux Team"

source=(
  "https://www.kernel.org/pub/linux/network/wireless/iwd-${version}.tar.xz"
)

sha256sums=(
  "c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9"
)

depends=("glibc" "libnl" "ell")
build_depends=("python")

prepare() {
  tar xf "${srcdir}/iwd-${version}.tar.xz"
}

build() {
  cd "${srcdir}/iwd-${version}"
  ./configure --prefix=/usr
  make
}

install() {
  cd "${srcdir}/iwd-${version}"
  make DESTDIR="${pkgdir}" install
}

check() {
  cd "${srcdir}/iwd-${version}"
  make -j$(nproc) check
}
