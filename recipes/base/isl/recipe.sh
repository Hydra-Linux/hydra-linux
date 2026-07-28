name="isl"
version="0.26"
release="1"
license="MIT"
maintainer="Hydra Linux Team"
source=("https://libisl.sourceforge.io/isl-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("gmp")
build_depends=()
prepare() { tar xf "${srcdir}/isl-${version}.tar.xz"; }
build() { cd "${srcdir}/isl-${version}" && ./configure --prefix=/usr --disable-static && make -j$(nproc); }
install() { cd "${srcdir}/isl-${version}" && make DESTDIR="${pkgdir}" install; }
