name="expat"
version="2.6.3"
release="1"
license="MIT"
maintainer="Hydra Linux Team"
source=("https://github.com/libexpat/libexpat/releases/download/R_2_6_3/expat-${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/expat-${version}.tar.gz"; }
build() { cd "${srcdir}/expat-${version}" && ./configure --prefix=/usr --disable-static && make -j$(nproc); }
install() { cd "${srcdir}/expat-${version}" && make DESTDIR="${pkgdir}" install; }
