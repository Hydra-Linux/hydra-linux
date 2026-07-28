name="findutils"
version="4.10.0"
release="1"
license="GPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/findutils/findutils-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/findutils-${version}.tar.xz"; }
build() { cd "${srcdir}/findutils-${version}" && ./configure --prefix=/usr --localstatedir=/var/lib/locate && make -j$(nproc); }
install() { cd "${srcdir}/findutils-${version}" && make DESTDIR="${pkgdir}" install; }
