name="e2fsprogs"
version="1.47.1"
release="1"
license="GPL-2.0-only"
maintainer="Hydra Linux Team"
source=("https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v${version}/e2fsprogs-${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/e2fsprogs-${version}.tar.gz" && mkdir -p "${srcdir}/build"; }
build() { cd "${srcdir}/build" && ../e2fsprogs-${version}/configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/build" && make DESTDIR="${pkgdir}" install; }
