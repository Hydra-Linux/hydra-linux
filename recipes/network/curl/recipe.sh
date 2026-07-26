name="curl"
version="8.9"
release="1"
license="MIT"
maintainer="Hydra Linux Team"

source=(
  "https://curl.se/download/curl-${version}.tar.xz"
)

sha256sums=(
  "0000000000000000000000000000000000000000000000000000000000000000"
)

depends=("glibc" "openssl" "zlib" "libpsl")
build_depends=("make" "pkgconf")

build() {
  cd "${srcdir}/curl-${version}"
  ./configure --prefix=/usr --with-openssl --with-zlib
  make -j$(nproc)
}

install() {
  cd "${srcdir}/curl-${version}"
  make DESTDIR="${pkgdir}" install
}
