name="which"
version="2.21"
release="1"
license="GPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/which/which-${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=()
prepare() { tar xf "${srcdir}/which-${version}.tar.gz"; }
build() { cd "${srcdir}/which-${version}" && ./configure --prefix=/usr && make -j$(nproc); }
install() { cd "${srcdir}/which-${version}" && make DESTDIR="${pkgdir}" install; }
