name="shadow"
version="4.16.0"
release="1"
license="BSD-3-Clause"
maintainer="Hydra Linux Team"
source=("https://github.com/shadow-maint/shadow/releases/download/${version}/shadow-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("pam" "linux-headers")
build_depends=()
prepare() { tar xf "${srcdir}/shadow-${version}.tar.xz"; }
build() { cd "${srcdir}/shadow-${version}" && ./configure --prefix=/usr --sysconfdir=/etc --enable-shared --with-libpam && make -j$(nproc); }
install() { cd "${srcdir}/shadow-${version}" && make DESTDIR="${pkgdir}" install; }
