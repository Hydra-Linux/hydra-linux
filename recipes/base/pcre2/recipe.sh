name="pcre2"
version="10.44"
release="1"
license="BSD-3-Clause"
maintainer="Hydra Linux Team"
source=("https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${version}/pcre2-${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("zlib" "bzip2" "readline")
build_depends=()
prepare() { tar xf "${srcdir}/pcre2-${version}.tar.gz"; }
build() { cd "${srcdir}/pcre2-${version}" && ./configure --prefix=/usr --disable-static --enable-pcre2-16 --enable-pcre2-32 && make -j$(nproc); }
install() { cd "${srcdir}/pcre2-${version}" && make DESTDIR="${pkgdir}" install; }
