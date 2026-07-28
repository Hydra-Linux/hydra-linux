name="ntfs-3g"
version="2022.10.3"
release="1"
license="GPL-2.0-or-later"
maintainer="Hydra Linux Team"
source=("https://tuxera.com/opensource/ntfs-3g_ntfsprogs-${version}.tgz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("zlib")
build_depends=()
prepare() { tar xf "${srcdir}/ntfs-3g_ntfsprogs-${version}.tgz"; }
build() { cd "${srcdir}/ntfs-3g_ntfsprogs-${version}" && ./configure --prefix=/usr --disable-static && make -j$(nproc); }
install() { cd "${srcdir}/ntfs-3g_ntfsprogs-${version}" && make DESTDIR="${pkgdir}" install; }
