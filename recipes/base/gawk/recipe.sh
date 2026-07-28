name="gawk"
version="5.3.0"
release="1"
license="GPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/gawk/gawk-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("mpfr" "readline")
build_depends=()
prepare() { tar xf "${srcdir}/gawk-${version}.tar.xz"; }
build() { cd "${srcdir}/gawk-${version}" && ./configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/gawk-${version}" && make DESTDIR="${pkgdir}" install; }
