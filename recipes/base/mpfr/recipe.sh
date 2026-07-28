name="mpfr"
version="4.2.1"
release="1"
license="LGPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/mpfr/mpfr-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("gmp")
build_depends=()
prepare() { tar xf "${srcdir}/mpfr-${version}.tar.xz"; }
build() { cd "${srcdir}/mpfr-${version}" && ./configure --prefix=/usr --disable-static && make -j$(nproc); }
install() { cd "${srcdir}/mpfr-${version}" && make DESTDIR="${pkgdir}" install; }
