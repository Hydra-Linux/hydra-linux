name="glibc"
version="2.39"
release="1"
license="LGPL-2.1-only"
maintainer="Hydra Linux Team"

source=(
  "https://ftp.gnu.org/gnu/glibc/glibc-${version}.tar.xz"
)

sha256sums=(
  "d359b16e25322daff7096203e8161e3f3c4d646821190bea14d4859f9b1dcc38"
)

depends=()
build_depends=("linux-kernel-headers")

prepare() {
  tar xf "${srcdir}/glibc-${version}.tar.xz"
}

build() {
  cd "${srcdir}/glibc-${version}"
  mkdir build
  cd build
  ../configure --prefix=/usr
  make
}

install() {
  cd "${srcdir}/glibc-${version}/build"
  make DESTDIR="${pkgdir}" install
}

check() {
  cd "${srcdir}/glibc-${version}/build"
  make -j$(nproc) check
}
