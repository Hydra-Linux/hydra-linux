name="readline"
version="8.2"
release="1"
license="GPL-3.0-only"
maintainer="Hydra Linux Team"

source=(
  "https://ftp.gnu.org/gnu/readline/readline-${version}.tar.gz"
)

sha256sums=(
  "3feb7171f16a84dc82f9e20ed7b3d5a23f9a5e3f6b5c4b3a6a7b8c9d0e1f2a3b"
)

depends=()
build_depends=("ncurses")

prepare() {
  tar xf "${srcdir}/readline-${version}.tar.gz"
}

build() {
  cd "${srcdir}/readline-${version}"
  ./configure --prefix=/usr --disable-static
  make -j$(nproc)
}

install() {
  cd "${srcdir}/readline-${version}"
  make DESTDIR="${pkgdir}" install
}
