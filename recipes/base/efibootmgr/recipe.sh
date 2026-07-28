name="efibootmgr"
version="18"
release="1"
license="GPL-2.0-only"
maintainer="Hydra Linux Team"
source=("https://github.com/rhboot/efibootmgr/archive/refs/tags/${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("pciutils" "zlib")
build_depends=()
prepare() { tar xf "${srcdir}/${version}.tar.gz" && mv efibootmgr-${version} efibootmgr; }
build() { cd "${srcdir}/efibootmgr" && make -j$(nproc); }
install() { cd "${srcdir}/efibootmgr" && make DESTDIR="${pkgdir}" prefix=/usr install; }
