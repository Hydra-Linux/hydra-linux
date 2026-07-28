name="polkit"
version="125"
release="1"
license="LGPL-2.0-or-later"
maintainer="Hydra Linux Team"
source=("https://www.freedesktop.org/software/polkit/releases/polkit-${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("glib" "expat" "pam" "elogind")
build_depends=("meson" "ninja")
prepare() { tar xf "${srcdir}/polkit-${version}.tar.gz"; }
build() { cd "${srcdir}/polkit-${version}" && meson setup build --prefix=/usr -Dsession_tracking=elogind -Dauthfw=pam && ninja -C build; }
install() { cd "${srcdir}/polkit-${version}" && DESTDIR="${pkgdir}" ninja -C build install; }
