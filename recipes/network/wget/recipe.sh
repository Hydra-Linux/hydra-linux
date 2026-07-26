name="wget"
version="1.25"
release="1"
license="GPL-3.0-only"
maintainer="Hydra Linux Team"

source=(
  "https://ftp.gnu.org/gnu/wget/wget-${version}.tar.xz"
)

sha256sums=(
  "0000000000000000000000000000000000000000000000000000000000000000"
)

depends=("glibc" "openssl" "zlib" "pcre2")
build_depends=("make")

build() {
  cd "${srcdir}/wget-${version}"
  ./configure --prefix=/usr --with-ssl=openssl
  make -j$(nproc)
}

install() {
  cd "${srcdir}/wget-${version}"
  make DESTDIR="${pkgdir}" install
}
