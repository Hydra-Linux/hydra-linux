name="flash"
version="1.0"
release="1"
license="GPL-2.0-only"
maintainer="Hydra Linux Team"

source=(
  "file:///usr/src/flash"
)

sha256sums=(
  "SKIP"
)

depends=("glibc" "bash" "coreutils")
build_depends=("gcc" "make")

prepare() {
  cp -a "${srcdir}/flash" .
}

build() {
  cd "${srcdir}/flash"
  make
}

install() {
  cd "${srcdir}/flash"
  make DESTDIR="${pkgdir}" install
}

check() {
  cd "${srcdir}/flash"
  make test
}
