name="git"
version="2.46"
release="1"
license="GPL-2.0-only"
maintainer="Hydra Linux Team"

source=(
  "https://www.kernel.org/pub/software/scm/git/git-${version}.tar.xz"
)

sha256sums=(
  "0000000000000000000000000000000000000000000000000000000000000000"
)

depends=("glibc" "curl" "zlib" "openssl" "expat" "pcre2")
build_depends=("make")

build() {
  cd "${srcdir}/git-${version}"
  ./configure --prefix=/usr
  make -j$(nproc)
}

install() {
  cd "${srcdir}/git-${version}"
  make DESTDIR="${pkgdir}" install
}
