name="automake"
version="1.17"
release="1"
license="GPL-2.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/automake/automake-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("autoconf")
build_depends=()
prepare() { tar xf "${srcdir}/automake-${version}.tar.xz"; }
build() { cd "${srcdir}/automake-${version}" && ./configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/automake-${version}" && make DESTDIR="${pkgdir}" install; }
