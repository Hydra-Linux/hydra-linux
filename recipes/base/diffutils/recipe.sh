name="diffutils"
version="3.10"
release="1"
license="GPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/diffutils/diffutils-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/diffutils-${version}.tar.xz"; }
build() { cd "${srcdir}/diffutils-${version}" && ./configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/diffutils-${version}" && make DESTDIR="${pkgdir}" install; }
