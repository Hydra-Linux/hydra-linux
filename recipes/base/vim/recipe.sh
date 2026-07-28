name="vim"
version="9.1.0660"
release="1"
license="Vim"
maintainer="Hydra Linux Team"
source=("https://github.com/vim/vim/archive/refs/tags/v${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("ncurses" "libxml2" "python3")
build_depends=()
prepare() { tar xf "${srcdir}/v${version}.tar.gz"; }
build() { cd "${srcdir}/vim-${version}" && ./configure --prefix=/usr --with-features=huge --enable-python3interp --enable-multibyte && make -j$(nproc); }
install() { cd "${srcdir}/vim-${version}" && make DESTDIR="${pkgdir}" install; }
