name="bash"
version="5.2.32"
release="1"
license="GPL-3.0-only"
maintainer="Hydra Linux Team"

source=(
  "https://ftp.gnu.org/gnu/bash/bash-${version}.tar.gz"
)

sha256sums=(
  "7fa5e0e9d9b1e4c0b3a0b2f1a5c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c"
)

depends=("glibc" "readline")
build_depends=()

prepare() {
  tar xf "${srcdir}/bash-${version}.tar.gz"
}

build() {
  cd "${srcdir}/bash-${version}"
  ./configure --prefix=/usr
  make
}

install() {
  cd "${srcdir}/bash-${version}"
  make DESTDIR="${pkgdir}" install
}

check() {
  cd "${srcdir}/bash-${version}"
  make -j$(nproc) check
}
