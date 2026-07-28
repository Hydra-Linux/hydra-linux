name="dosfstools"
version="4.2"
release="1"
license="GPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://github.com/dosfstools/dosfstools/releases/download/v${version}/dosfstools-${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/dosfstools-${version}.tar.gz"; }
build() { cd "${srcdir}/dosfstools-${version}" && ./configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/dosfstools-${version}" && make DESTDIR="${pkgdir}" install; }
