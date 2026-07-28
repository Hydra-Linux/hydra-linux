name="bison"
version="3.8.2"
release="1"
license="GPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/bison/bison-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("m4")
build_depends=()
prepare() { tar xf "${srcdir}/bison-${version}.tar.xz"; }
build() { cd "${srcdir}/bison-${version}" && ./configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/bison-${version}" && make DESTDIR="${pkgdir}" install; }
