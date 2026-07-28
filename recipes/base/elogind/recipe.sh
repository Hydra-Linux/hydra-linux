name="elogind"
version="255.6"
release="1"
license="LGPL-2.1-or-later"
maintainer="Hydra Linux Team"
source=("https://github.com/elogind/elogind/archive/refs/tags/v${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("dbus" "polkit")
build_depends=("meson" "ninja")
prepare() { tar xf "${srcdir}/v${version}.tar.gz"; }
build() { cd "${srcdir}/elogind-${version}" && meson setup build --prefix=/usr && ninja -C build; }
install() { cd "${srcdir}/elogind-${version}" && DESTDIR="${pkgdir}" ninja -C build install; }
