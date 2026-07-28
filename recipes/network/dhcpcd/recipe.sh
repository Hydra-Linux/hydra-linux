name="dhcpcd"
version="10.0.8"
release="1"
license="BSD-2-Clause"
maintainer="Hydra Linux Team"
source=("https://github.com/NetworkConfiguration/dhcpcd/releases/download/v${version}/dhcpcd-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/dhcpcd-${version}.tar.xz"; }
build() { cd "${srcdir}/dhcpcd-${version}" && ./configure --prefix=/usr --sysconfdir=/etc --dbdir=/var/lib/dhcpcd && make -j$(nproc); }
install() { cd "${srcdir}/dhcpcd-${version}" && make DESTDIR="${pkgdir}" install; }
