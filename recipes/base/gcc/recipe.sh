name="gcc"
version="14.2.0"
release="1"
license="GPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/gcc/gcc-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("gmp" "mpfr" "mpc" "isl" "binutils" "glibc" "linux-headers")
build_depends=("make")
prepare() { tar xf "${srcdir}/gcc-${version}.tar.xz" && mkdir -p "${srcdir}/build"; }
build() {
  cd "${srcdir}/build"
  ../gcc-${version}/configure --prefix=/usr --enable-languages=c,c++ --disable-multilib --disable-libsanitizer --enable-default-pie --enable-default-ssp
  make -j$(nproc)
}
install() { cd "${srcdir}/build" && make DESTDIR="${pkgdir}" install; }
