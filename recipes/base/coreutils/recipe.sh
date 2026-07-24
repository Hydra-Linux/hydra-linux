name="coreutils"
version="9.5"
release="1"
license="GPL-3.0-only"
maintainer="Hydra Linux Team"

source=(
  "https://ftp.gnu.org/gnu/coreutils/coreutils-${version}.tar.xz"
)

sha256sums=(
  "a66e4acf9791b1e3023b8b3eac59d3770e1b9da4fa7b7e0e3dabb8b0c3d3d4e5"
)

depends=("glibc")
build_depends=()

prepare() {
  tar xf "${srcdir}/coreutils-${version}.tar.xz"
}

build() {
  cd "${srcdir}/coreutils-${version}"
  ./configure --prefix=/usr
  make
}

install() {
  cd "${srcdir}/coreutils-${version}"
  make DESTDIR="${pkgdir}" install
}

check() {
  cd "${srcdir}/coreutils-${version}"
  make -j$(nproc) check
}
