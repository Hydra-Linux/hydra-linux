name="busybox"
version="1.36.1"
release="1"
license="GPL-2.0-only"
maintainer="Hydra Linux Team"
source=("https://busybox.net/downloads/busybox-${version}.tar.bz2")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/busybox-${version}.tar.bz2" && cp "${srcdir}/busybox-${version}/configs/defconfig" "${srcdir}/busybox-${version}/.config"; }
build() { cd "${srcdir}/busybox-${version}" && make -j$(nproc) && make busybox-install; }
install() { cd "${srcdir}/busybox-${version}" && make DESTDIR="${pkgdir}" CONFIG_PREFIX="${pkgdir}" install; }
