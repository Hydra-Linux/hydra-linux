name="python3"
version="3.12.5"
release="1"
license="Python-2.0"
maintainer="Hydra Linux Team"
source=("https://www.python.org/ftp/python/${version}/Python-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("libffi" "zlib" "bzip2" "xz" "readline" "ncurses" "openssl" "expat")
build_depends=()
prepare() { tar xf "${srcdir}/Python-${version}.tar.xz"; }
build() { cd "${srcdir}/Python-${version}" && ./configure --prefix=/usr --enable-shared --with-system-expat --with-system-ffi --with-ensurepip=install && make -j$(nproc); }
install() { cd "${srcdir}/Python-${version}" && make DESTDIR="${pkgdir}" install; }
