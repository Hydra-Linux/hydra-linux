name="util-linux"
version="2.40"
release="1"
license="GPL-2.0-only"
maintainer="Hydra Linux Team"

source=(
  "https://www.kernel.org/pub/linux/utils/util-linux/v2.40/util-linux-${version}.tar.xz"
)

sha256sums=(
  "b2a4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3"
)

depends=("glibc" "ncurses" "zlib")
build_depends=()

prepare() {
  tar xf "${srcdir}/util-linux-${version}.tar.xz"
}

build() {
  cd "${srcdir}/util-linux-${version}"
  ./configure --prefix=/usr
  make
}

install() {
  cd "${srcdir}/util-linux-${version}"
  make DESTDIR="${pkgdir}" install
}

check() {
  cd "${srcdir}/util-linux-${version}"
  make -j$(nproc) check
}
