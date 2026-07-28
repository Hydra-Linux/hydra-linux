name="dbus"
version="1.14.10"
release="1"
license="AFL-2.1"
maintainer="Hydra Linux Team"
source=("https://dbus.freedesktop.org/releases/dbus/dbus-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("expat")
build_depends=()
prepare() { tar xf "${srcdir}/dbus-${version}.tar.xz"; }
build() { cd "${srcdir}/dbus-${version}" && ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static --disable-systemd && make -j$(nproc); }
install() { cd "${srcdir}/dbus-${version}" && make DESTDIR="${pkgdir}" install; }
