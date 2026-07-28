name="ncurses"
version="6.5"
release="1"
license="MIT"
maintainer="Hydra Linux Team"

source=(
  "https://ftp.gnu.org/gnu/ncurses/ncurses-${version}.tar.gz"
)

sha256sums=(
  "e4a6e9b1b75c2f6f6b3b5c3a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b"
)

depends=()
build_depends=()

prepare() {
  tar xf "${srcdir}/ncurses-${version}.tar.gz"
}

build() {
  cd "${srcdir}/ncurses-${version}"
  ./configure --prefix=/usr --with-shared --without-normal --without-debug --enable-widec --enable-pc-files --with-pkg-config=/usr/lib/pkgconfig
  make -j$(nproc)
}

install() {
  cd "${srcdir}/ncurses-${version}"
  make DESTDIR="${pkgdir}" install
}
