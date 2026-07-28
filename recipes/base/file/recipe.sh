name="file"
version="5.45"
release="1"
license="BSD-2-Clause"
maintainer="Hydra Linux Team"
source=("https://astron.com/pub/file/file-${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("zlib")
build_depends=()
prepare() { tar xf "${srcdir}/file-${version}.tar.gz"; }
build() { cd "${srcdir}/file-${version}" && ./configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/file-${version}" && make DESTDIR="${pkgdir}" install; }
