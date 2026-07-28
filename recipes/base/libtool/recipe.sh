name="libtool"
version="2.5.4"
release="1"
license="GPL-2.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/libtool/libtool-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("m4" "autoconf" "automake")
build_depends=()
prepare() { tar xf "${srcdir}/libtool-${version}.tar.xz"; }
build() { cd "${srcdir}/libtool-${version}" && ./configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/libtool-${version}" && make DESTDIR="${pkgdir}" install; }
