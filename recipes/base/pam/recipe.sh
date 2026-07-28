name="pam"
version="1.6.1"
release="1"
license="GPL-2.0-or-later"
maintainer="Hydra Linux Team"
source=("https://github.com/linux-pam/linux-pam/releases/download/v${version}/Linux-PAM-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("libxml2" "flex" "linux-headers")
build_depends=()
prepare() { tar xf "${srcdir}/Linux-PAM-${version}.tar.xz"; }
build() { cd "${srcdir}/Linux-PAM-${version}" && ./configure --prefix=/usr --sysconfdir=/etc --disable-static --enable-securedir=/usr/lib/security && make -j$(nproc); }
install() { cd "${srcdir}/Linux-PAM-${version}" && make DESTDIR="${pkgdir}" install; }
