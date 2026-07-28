name="libffi"
version="3.4.6"
release="1"
license="MIT"
maintainer="Hydra Linux Team"
source=("https://github.com/libffi/libffi/releases/download/v${version}/libffi-${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/libffi-${version}.tar.gz"; }
build() { cd "${srcdir}/libffi-${version}" && ./configure --prefix=/usr --disable-static && make -j$(nproc); }
install() { cd "${srcdir}/libffi-${version}" && make DESTDIR="${pkgdir}" install; }
