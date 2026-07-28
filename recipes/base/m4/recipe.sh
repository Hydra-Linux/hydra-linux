name="m4"
version="1.4.19"
release="1"
license="GPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/m4/m4-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/m4-${version}.tar.xz"; }
build() { cd "${srcdir}/m4-${version}" && ./configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/m4-${version}" && make DESTDIR="${pkgdir}" install; }
