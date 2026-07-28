name="libxml2"
version="2.13.4"
release="1"
license="MIT"
maintainer="Hydra Linux Team"
source=("https://download.gnome.org/sources/libxml2/2.13/libxml2-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("xz" "zlib" "readline")
build_depends=()
prepare() { tar xf "${srcdir}/libxml2-${version}.tar.xz"; }
build() { cd "${srcdir}/libxml2-${version}" && ./configure --prefix=/usr --disable-static --without-python && make -j$(nproc); }
install() { cd "${srcdir}/libxml2-${version}" && make DESTDIR="${pkgdir}" install; }
