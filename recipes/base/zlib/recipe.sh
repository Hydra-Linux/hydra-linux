name="zlib"
version="1.3.1"
release="1"
license="Zlib"
maintainer="Hydra Linux Team"
source=("https://zlib.net/zlib-${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/zlib-${version}.tar.gz"; }
build() { cd "${srcdir}/zlib-${version}" && ./configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/zlib-${version}" && make DESTDIR="${pkgdir}" install; }
