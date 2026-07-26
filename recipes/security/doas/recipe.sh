name="doas"
version="6.3"
release="1"
license="ISC"
maintainer="Hydra Linux Team"

source=(
  "https://github.com/duncaen/opendoas/archive/refs/tags/v${version}.tar.gz"
)

sha256sums=(
  "0000000000000000000000000000000000000000000000000000000000000000"
)

depends=("glibc" "libbsd" "pam")
build_depends=("make" "bison")

build() {
  cd "${srcdir}/opendoas-${version}"
  ./configure --prefix=/usr --with-pam
  make -j$(nproc)
}

install() {
  cd "${srcdir}/opendoas-${version}"
  make DESTDIR="${pkgdir}" install
  chmod 4755 "${pkgdir}/usr/bin/doas"
}
