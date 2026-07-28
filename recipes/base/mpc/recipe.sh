name="mpc"
version="1.3.1"
release="1"
license="LGPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/mpc/mpc-${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("gmp" "mpfr")
build_depends=()
prepare() { tar xf "${srcdir}/mpc-${version}.tar.gz"; }
build() { cd "${srcdir}/mpc-${version}" && ./configure --prefix=/usr --disable-static && make -j$(nproc); }
install() { cd "${srcdir}/mpc-${version}" && make DESTDIR="${pkgdir}" install; }
