name="flex"
version="2.6.4"
release="1"
license="BSD-2-Clause"
maintainer="Hydra Linux Team"
source=("https://github.com/westes/flex/releases/download/v${version}/flex-${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("m4")
build_depends=()
prepare() { tar xf "${srcdir}/flex-${version}.tar.gz"; }
build() { cd "${srcdir}/flex-${version}" && ./configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/flex-${version}" && make DESTDIR="${pkgdir}" install; }
