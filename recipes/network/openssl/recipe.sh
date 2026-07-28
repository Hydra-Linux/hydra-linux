name="openssl"
version="3.3.1"
release="1"
license="Apache-2.0"
maintainer="Hydra Linux Team"

source=(
  "https://www.openssl.org/source/openssl-${version}.tar.gz"
)

sha256sums=(
  "777f83a1a5b1a7b5b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0"
)

depends=()
build_depends=()

prepare() {
  tar xf "${srcdir}/openssl-${version}.tar.gz"
}

build() {
  cd "${srcdir}/openssl-${version}"
  ./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic
  make -j$(nproc)
}

install() {
  cd "${srcdir}/openssl-${version}"
  make DESTDIR="${pkgdir}" install
}
