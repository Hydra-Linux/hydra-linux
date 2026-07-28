name="patch"
version="2.7.6"
release="1"
license="GPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/patch/patch-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/patch-${version}.tar.xz"; }
build() { cd "${srcdir}/patch-${version}" && ./configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/patch-${version}" && make DESTDIR="${pkgdir}" install; }
