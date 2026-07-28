name="grep"
version="3.11"
release="1"
license="GPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/grep/grep-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("pcre2")
build_depends=()
prepare() { tar xf "${srcdir}/grep-${version}.tar.xz"; }
build() { cd "${srcdir}/grep-${version}" && ./configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/grep-${version}" && make DESTDIR="${pkgdir}" install; }
