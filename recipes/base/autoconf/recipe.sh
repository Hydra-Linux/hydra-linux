name="autoconf"
version="2.72"
release="1"
license="GPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/autoconf/autoconf-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("m4")
build_depends=()
prepare() { tar xf "${srcdir}/autoconf-${version}.tar.xz"; }
build() { cd "${srcdir}/autoconf-${version}" && ./configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/autoconf-${version}" && make DESTDIR="${pkgdir}" install; }
