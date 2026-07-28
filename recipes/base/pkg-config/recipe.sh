name="pkg-config"
version="0.29.2"
release="1"
license="GPL-2.0-or-later"
maintainer="Hydra Linux Team"
source=("https://pkgconfig.freedesktop.org/releases/pkg-config-${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/pkg-config-${version}.tar.gz"; }
build() { cd "${srcdir}/pkg-config-${version}" && ./configure --prefix=/usr --with-internal-glib && make -j$(nproc); }
install() { cd "${srcdir}/pkg-config-${version}" && make DESTDIR="${pkgdir}" install; }
