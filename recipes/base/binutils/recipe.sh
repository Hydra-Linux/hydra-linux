name="binutils"
version="2.43.1"
release="1"
license="GPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/binutils/binutils-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("zlib")
build_depends=("make")
prepare() { tar xf "${srcdir}/binutils-${version}.tar.xz" && mkdir -p "${srcdir}/build"; }
build() { cd "${srcdir}/build" && ../binutils-${version}/configure --prefix=/usr --enable-shared --disable-werror && make -j$(nproc); }
install() { cd "${srcdir}/build" && make DESTDIR="${pkgdir}" install; }
