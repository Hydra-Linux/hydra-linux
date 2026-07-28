name="grub"
version="2.12"
release="1"
license="GPL-3.0-or-later"
maintainer="Hydra Linux Team"
source=("https://ftp.gnu.org/gnu/grub/grub-${version}.tar.xz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("gettext" "freetype" "device-mapper")
build_depends=("python3")
prepare() { tar xf "${srcdir}/grub-${version}.tar.xz"; }
build() { cd "${srcdir}/grub-${version}" && ./configure --prefix=/usr --disable-werror --enable-grub-mkfont --with-platform=efi && make -j$(nproc); }
install() { cd "${srcdir}/grub-${version}" && make DESTDIR="${pkgdir}" install; }
