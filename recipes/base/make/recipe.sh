name="make"
version="4.4.1"
release="1"
license="GPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/make/make-${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/make-${version}.tar.gz"; }
build() { cd "${srcdir}/make-${version}" && ./configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/make-${version}" && make DESTDIR="${pkgdir}" install; }
