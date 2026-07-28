name="bzip2"
version="1.0.8"
release="1"
license="BSD-4-Clause"
maintainer="Hydra Linux Team"
source=("https://sourceware.org/pub/bzip2/bzip2-${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/bzip2-${version}.tar.gz"; }
build() { cd "${srcdir}/bzip2-${version}" && make -j$(nproc) -f Makefile-libbz2_so && make -j$(nproc); }
install() { cd "${srcdir}/bzip2-${version}" && make DESTDIR="${pkgdir}" PREFIX=/usr install && cp -a libbz2.so* "${pkgdir}/usr/lib/"; }
