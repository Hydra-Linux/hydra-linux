name="gettext"
version="0.22.5"
release="1"
license="GPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/gettext/gettext-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("libxml2" "ncurses")
build_depends=()
prepare() { tar xf "${srcdir}/gettext-${version}.tar.xz"; }
build() { cd "${srcdir}/gettext-${version}" && ./configure --prefix=/usr --disable-static && make -j$(nproc); }
install() { cd "${srcdir}/gettext-${version}" && make DESTDIR="${pkgdir}" install; }
