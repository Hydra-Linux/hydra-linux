name="kmod"
version="33"
release="1"
license="LGPL-2.1-or-later"
maintainer="Hydra Linux Team"
source=("https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("zlib" "xz" "zstd")
build_depends=()
prepare() { tar xf "${srcdir}/kmod-${version}.tar.xz"; }
build() { cd "${srcdir}/kmod-${version}" && ./configure --prefix=/usr --with-openssl && make -j$(nproc); }
install() { cd "${srcdir}/kmod-${version}" && make DESTDIR="${pkgdir}" install; }
