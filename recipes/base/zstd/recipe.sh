name="zstd"
version="1.5.6"
release="1"
license="BSD-3-Clause"
maintainer="Hydra Linux Team"
source=("https://github.com/facebook/zstd/releases/download/v${version}/zstd-${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/zstd-${version}.tar.gz"; }
build() { cd "${srcdir}/zstd-${version}" && make -j$(nproc); }
install() { cd "${srcdir}/zstd-${version}" && make DESTDIR="${pkgdir}" prefix=/usr install; }
