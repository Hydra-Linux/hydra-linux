name="linux-headers"
version="6.11"
release="1"
license="GPL-2.0-only"
maintainer="Hydra Linux Team"
source=("https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/linux-${version}.tar.xz"; }
build() { cd "${srcdir}/linux-${version}" && make ARCH=x86_64 headers; }
install() { cd "${srcdir}/linux-${version}" && make ARCH=x86_64 INSTALL_HDR_PATH="${pkgdir}/usr" headers_install; }
