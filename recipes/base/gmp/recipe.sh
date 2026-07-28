name="gmp"
version="6.3.0"
release="1"
license="LGPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/gmp/gmp-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/gmp-${version}.tar.xz"; }
build() { cd "${srcdir}/gmp-${version}" && ./configure --prefix=/usr --enable-cxx --disable-static && make -j$(nproc); }
install() { cd "${srcdir}/gmp-${version}" && make DESTDIR="${pkgdir}" install; }
