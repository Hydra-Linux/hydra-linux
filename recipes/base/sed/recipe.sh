name="sed"
version="4.9"
release="1"
license="GPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/sed/sed-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/sed-${version}.tar.xz"; }
build() { cd "${srcdir}/sed-${version}" && ./configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/sed-${version}" && make DESTDIR="${pkgdir}" install; }
