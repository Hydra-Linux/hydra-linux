name="xz"
version="5.6.2"
release="1"
license="Public-Domain"
maintainer="Hydra Linux Team"
source=("https://github.com/tukaani-project/xz/releases/download/v${version}/xz-${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/xz-${version}.tar.gz"; }
build() { cd "${srcdir}/xz-${version}" && ./configure --prefix=/usr --disable-static && make -j$(nproc); }
install() { cd "${srcdir}/xz-${version}" && make DESTDIR="${pkgdir}" install; }
